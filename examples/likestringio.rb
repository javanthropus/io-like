require 'rbconfig/sizeof'

require 'io/like'
require 'io/like_helpers/abstract_io'
require 'io/like_helpers/delegated_io'

class LikeStringIO < IO::Like
  class StringWrapper < IO::LikeHelpers::AbstractIO
    def initialize(
      string,
      append: false,
      readable: false,
      truncate: false,
      writable: false
    )
      super()

      @string = string
      @append = append
      @readable = readable
      @truncate = truncate
      @writable = writable
      @pos = 0

      raise Errno::EACCES if writable? && string && string.frozen?

      @string.clear if @truncate
    end

    def append?
      @append
    end

    def dup
      self
    end

    attr_reader :encoding

    def encoding=(encoding)
      return nil if ! string
      encoding ||= @string.encoding
      @encoding = encoding
      @string.force_encoding(encoding) unless @string.frozen?
    end

    def flush
      nil
    end

    def fsync
      0
    end

    def nonblock=(nonblock)
      nil
    end

    def nread
      assert_readable
      return 0 if ! string
      [0, string.bytesize - @pos].max
    end

    def peek(length = nil)
      if length.nil?
        length = string.bytesize - @pos if string
      else
        length = Integer(length)
        raise ArgumentError, 'length must be at least 0' if length < 0
      end

      assert_readable

      return String.new(encoding: Encoding::BINARY) if ! string || @pos > string.bytesize
      return string.b[@pos, length]
    end

    def read(length, buffer: nil, buffer_offset: 0)
      length = Integer(length)
      raise ArgumentError, 'length must be at least 0' if length < 0
      if ! buffer.nil?
        if buffer_offset < 0 || buffer_offset >= buffer.bytesize
          raise ArgumentError, 'buffer_offset is not a valid buffer index'
        end
        if buffer.bytesize - buffer_offset < length
          raise ArgumentError, 'length is greater than available buffer space'
        end
      end

      assert_readable

      raise EOFError, 'end of file reached' if ! string || @pos >= string.bytesize

      content = string.b[@pos, length]
      @pos += content.bytesize
      return content if buffer.nil?

      buffer[buffer_offset, content.bytesize] = content
      return content.bytesize
    end

    def read_buffer_empty?
      return true if ! string
      @pos >= string.bytesize
    end

    def readable?
      @readable
    end

    def refill
      assert_readable
      raise EOFError, 'end of file reached'
    end

    def seek(amount, whence)
      assert_open

      case whence
      when IO::SEEK_SET, :SET
        new_pos = amount
      when IO::SEEK_CUR, :CUR
        new_pos = @pos + amount
      when IO::SEEK_END, :END
        new_pos = string.bytesize + amount
      else
        raise Errno::EINVAL, 'Invalid argument - invalid whence'
      end

      return 0 if ! string

      raise Errno::EINVAL, 'Invalid argument' if new_pos < 0

      @pos = new_pos
    end

    def skip(length = nil)
      if length.nil?
        length = string.bytesize - @pos
      else
        length = Integer(length)
        raise ArgumentError, 'length must be at least 0' if length < 0
      end

      assert_readable

      return 0 if ! string

      remaining = string.bytesize - @pos
      length = remaining if length > remaining
      @pos += length

      length
    end

    attr_reader :string

    def string=(string)
      @pos = 0
      @string = string
    end

    def truncate(length)
      length = Integer(length)
      raise Errno::EINVAL, 'Invalid argument - negative length' if length < 0

      assert_writable

      return 0 if ! string

      string.force_encoding(Encoding::BINARY)
      if length < string.bytesize
        string.slice!(length..-1)
      elsif length > string.bytesize
        string << "\0".b * (length - string.bytesize)
      end
      string.force_encoding(encoding)

      0
    end

    def unread(buffer, length: buffer.bytesize)
      length = Integer(length)
      raise ArgumentError 'length must be at least 0' if length < 0

      assert_readable

      return nil if length == 0 || ! string

      replace_length = length
      @pos -= length
      if @pos < 0
        replace_length = length + @pos
        @pos = 0
      end

      string.force_encoding(Encoding::BINARY)
      pad_for_position
      string[@pos, replace_length] = buffer[0, length]
      string.force_encoding(encoding)

      nil
    rescue FrozenError
      raise IOError, 'not modifiable string'
    end

    def write_orig(buffer, length: buffer.bytesize)
      assert_writable

      @pos = string.bytesize if @append
      string.force_encoding(Encoding::BINARY)
      pad_for_position
      string[@pos, length] = buffer[0, length]
      string.force_encoding(encoding)
      @pos += length

      length
    rescue FrozenError
      raise IOError, 'not modifiable string'
    end

    def write(buffer)
      assert_writable

      return 0 if ! string

      if string.encoding != buffer.encoding &&
         string.encoding != Encoding::BINARY &&
         string.encoding != Encoding::ASCII
        if string.encoding.ascii_compatible? && buffer.ascii_only?
          buffer = buffer.dup
          buffer.force_encoding(Encoding::BINARY)
        elsif buffer.encoding != Encoding::BINARY &&
              buffer.encoding != Encoding::ASCII
          begin
            buffer = buffer.encode(string.encoding)
          rescue Encoding::UndefinedConversionError
            raise Encoding::CompatibilityError,
              'incompatible character encodings: %s and %s' %
              [string.encoding, buffer.encoding]
          end
        end
      end

      @pos = string.bytesize if @append
      pad_for_position
      if @pos == string.bytesize
        if string.encoding == Encoding::BINARY ||
           buffer.encoding == Encoding::BINARY
          string.force_encoding(Encoding::BINARY)
          string[@pos, buffer.bytesize] = buffer.b
          string.force_encoding(encoding)
          @pos += buffer.bytesize
        else
          string.concat(buffer)
          @pos = string.bytesize
        end
      else
        string.force_encoding(Encoding::BINARY)
        string[@pos, buffer.bytesize] = buffer.b
        string.force_encoding(encoding)
        @pos += buffer.bytesize
      end

      buffer.bytesize
    rescue FrozenError
      raise IOError, 'not modifiable string'
    end

    def writable?
      @writable
    end

    def write_buffer_empty?
      true
    end

    private

    def pad_for_position
      return if @pos <= string.bytesize

      # Pad any space between the end of the wrapped string and the current
      # position with null characters.
      string << "\0".b * (@pos - string.bytesize)

      nil
    rescue NoMemoryError
      raise ArgumentError, 'string size too big'
    end
  end

  class StringCharacterIO < IO::LikeHelpers::CharacterIO
    def set_encoding(ext_enc, int_enc, **opts)
      super
      buffered_io.encoding = external_encoding
      nil
    end

    ##
    # Override in order to provide special paragraph handling compatible with
    # StringIO.
    def read_line(separator: $/, limit: nil, chomp: false, discard_newlines: false)
      if separator == "\n\n" && discard_newlines
        # Paragraph mode is special:
        # 1. Leading runs of _linefeed_ characters are discarded as usual
        # 2. The separator is /(\r?\n){2,}/
        # 3. Chomping consumes all bytes from the line matching the separator as
        #    usual
        separator = Regexp.new("(\r?\n){2,}".b)
      elsif separator == $/
        separator = Regexp.new("\r?\n".b)
      end
      super
    end

    def write(buffer)
      buffered_io.write(buffer)
    end
  end

  class StringPipeline < IO::LikeHelpers::DelegatedIO
    def initialize(
      delegate,
      autoclose: true,
      encoding_opts: {},
      external_encoding: nil,
      internal_encoding: nil,
      sync: false
    )

      raise ArgumentError, 'delegate cannot be nil' if delegate.nil?

      super(delegate)

      @character_io = StringCharacterIO.new(
        buffered_io,
        blocking_io,
        encoding_opts: encoding_opts,
        external_encoding: external_encoding,
        internal_encoding: internal_encoding,
        sync: sync
      )
    end

    alias_method :buffered_io, :delegate
    public :buffered_io

    alias_method :blocking_io, :delegate
    attr_reader :character_io
    alias_method :concrete_io, :delegate

    private

    def initialize_copy(other)
      super

      @character_io = @character_io.dup
      @character_io.buffered_io = buffered_io
      @character_io.blocking_io = blocking_io
    end
  end

  VERSION = '0.0.1'
  MAX_LENGTH = RbConfig::LIMITS['LONG_MAX']

  def initialize(string = String.new, mode = nil, **opt)
    if block_given?
      warn("#{self.class.name}::new() does not take block; use #{self.class.name}::open() instead")
    end

    string, opt = parse_init_args(string, mode, **opt)
    string_encoding = string ? string.encoding : nil
    binmode = opt.delete(:binmode)
    encoding = opt.delete(:encoding)

    super(
      StringWrapper.new(string, **opt),
      binmode: binmode,
      external_encoding: encoding,
      pipeline_class: StringPipeline
    )

    if encoding.nil?
      self.binmode if string_encoding && !  string_encoding.ascii_compatible?
      set_encoding(string_encoding)
    end
  end

  def fcntl(*args)
    raise NotImplementedError
  end

  def reopen(*args)
    assert_thawed
    close
    @readable = @writable = nil

    if args.size == 1 && LikeStringIO === args[0]
      io = args[0]

      initialize(
        io.string,
        append: io.delegate.concrete_io.append?,
        binmode: io.binmode?,
        external_encoding: io.external_encoding,
        readable: io.delegate.concrete_io.readable?,
        writable: io.delegate.concrete_io.writable?
      )
      self.pos = io.pos
    else
      initialize(*args)
    end

    self
  end

  def set_encoding(ext_enc, int_enc = nil, **opts)
    assert_thawed

    if ! (ext_enc.nil? || Encoding === ext_enc)
      string_arg = String.new(ext_enc)
      begin
        split_idx = string_arg.rindex(':')
        unless split_idx.nil? || split_idx == 0
          ext_enc = string_arg[0...split_idx]
        end
      rescue Encoding::CompatibilityError
        # This is caused by failure to split on colon when the string argument
        # is not ASCII compatible.  Ignore it and use the argument as is.
      end
    end

    super(ext_enc)
  end

  def set_encoding_by_bom
    rewind
    binmode
    super
  end

  def size
    assert_thawed

    delegate.concrete_io.string.bytesize
  end

  def string
    assert_thawed

    delegate.concrete_io.string
  end

  def string=(string)
    assert_thawed

    delegate.concrete_io.string = string
  end

  def sync
    assert_thawed

    true
  end

  def sync=(sync)
    assert_thawed

    nil
  end

  ##
  # This is just a wrapper for #read that raises EOFError instead of returning
  # `nil`.
  def sysread(*args)
    result = read(*args)
    raise EOFError if result.nil?

    result
  end

  def truncate(length)
    assert_writable

    delegate.concrete_io.truncate(length)
  end

  protected

  def duplexed?
    readable? && writable?
  end

  private

  def assert_thawed
    if frozen?
      raise FrozenError, "can't modify frozen #{self.class.name}: #{inspect}"
    end
  end

  def assert_open
    assert_thawed
    super
  end

  def decode_mode(mode, frozen)
    case mode
    when Integer
      decode_integer_mode(mode)
    else
      decode_string_mode(mode, frozen)
    end
  end

  def decode_integer_mode(mode)
    result = {
      readable: false,
      writable: false,
      append: false,
      truncate: false
    }

    case mode & 0b11
    when File::RDONLY
      result[:readable] = true
    when File::WRONLY
      result[:writable] = true
    when File::RDWR
      result[:readable] = true
      result[:writable] = true
    end

    result[:append] = true if mode & File::APPEND == File::APPEND
    result[:truncate] = true if mode & File::TRUNC == File::TRUNC

    result
  end

  def decode_string_mode(mode, frozen)
    result = {
      readable: false,
      writable: false,
      append: false,
      truncate: false
    }

    if mode.nil?
      mode = frozen ? 'r' : 'r+'
    end
    simple_mode, encoding = mode.split(':')
    result[:encoding] = encoding unless encoding.nil?

    case simple_mode[0]
    when 'r'
      result[:readable] = true
    when 'w'
      result[:writable] = true
      result[:truncate] = true
    when 'a'
      result[:writable] = true
      result[:append] = true
    else
      raise ArgumentError, "invalid access mode #{mode}"
    end

    seen_b = false
    seen_t = false
    simple_mode[1..-1].each_char do |c|
      case c
      when '+'
        result[:readable] = true
        result[:writable] = true
      when 'b'
        raise ArgumentError, "invalid access mode #{mode}" if seen_t
        seen_b = true
        result[:binmode] = true
      when 't'
        raise ArgumentError, "invalid access mode #{mode}" if seen_b
        seen_t = true
        result[:textmode] = true
      else
        raise ArgumentError, "invalid access mode #{mode}"
      end
    end

    result
  end

  def parse_init_args(string = '', mode = nil, **opt)
    string = String.new(string) if string && ! (String === string)
    if ! (mode.nil? || opt[:mode].nil?)
      raise ArgumentError, 'mode specified twice'
    end
    mode = opt.delete(:mode) if mode.nil?

    decoded_mode = decode_mode(mode, string && string.frozen?)
    if decoded_mode.key?(:binmode) && ! opt[:textmode].nil? ||
       decoded_mode.key?(:textmode) && ! opt[:binmode].nil? ||
       ! (opt[:textmode].nil? || opt[:binmode].nil?)
      raise ArgumentError, 'both textmode and binmode specified'
    end
    if decoded_mode.key?(:binmode) && ! opt[:binmode].nil?
      raise ArgumentError, 'binmode specified twice'
    end
    if decoded_mode.key?(:textmode) && ! opt[:textmode].nil?
      raise ArgumentError, 'textmode specified twice'
    end
    opt_encodings_count =
      (opt.keys & [:encoding, :external_encoding, :internal_encoding]).size
    opt_encodings_count += 1 if decoded_mode.key?(:encoding)
    if opt_encodings_count > 1
      raise ArgumentError, 'encoding specified twice'
    end

    if opt.key?(:external_encoding)
      opt[:encoding] = opt.delete(:external_encoding)
    end
    # This is not actually used.
    opt.delete(:internal_encoding)

    return [string, opt.merge!(decoded_mode)]
  end

  ##
  # This overrides the handling of any buffer given to read operations to always
  # leave it in binary encoding, contrary to the behavior of real IO objects.
  def ensure_buffer(length, buffer)
    buffer.force_encoding(Encoding::BINARY) unless buffer.nil?
    super(length, buffer)
  end
end

# vim: ts=2 sw=2 et
