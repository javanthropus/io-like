require 'io/like'
require 'io/like_helpers/abstract_io'

class LikeStringIO < IO::Like
  class StringWrapper < IO::LikeHelpers::AbstractIO
    def initialize(string, **opt)
      super()

      @string = string
      @append = opt.fetch(:append, false)
      @readable = opt.fetch(:readable, false)
      @truncate = opt.fetch(:truncate, false)
      @writable = opt.fetch(:writable, false)
      @pos = 0

      raise Errno::EACCES if writable? && string.frozen?

      self.encoding = opt.fetch(:encoding, string.encoding)
      @string.clear if @truncate
    end

    def dup
      self
    end

    attr_reader :encoding

    def encoding=(encoding)
      encoding ||= @string.encoding
      @encoding = encoding
      @string.force_encoding(encoding) if writable?
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

    def read(length, buffer: nil)
      length = Integer(length)
      raise ArgumentError, 'length must be at least 0' if length < 0

      assert_readable

      raise EOFError, 'end of file reached' if @pos >= string.bytesize

      content = string.b[@pos, length]
      @pos += content.bytesize
      return content if buffer.nil?

      buffer[0, content.bytesize] = content
      return content.bytesize
    end
    alias_method :unbuffered_read, :read

    def readable?
      @readable
    end

    def read_buffer_empty?
      true
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

      raise Errno::EINVAL, 'Invalid argument' if new_pos < 0

      @pos = new_pos
    end
    alias_method :unbuffered_seek, :seek

    attr_reader :string

    def string=(string)
      @pos = 0
      @string = string
    end

    def truncate(length)
      length = Integer(length)
      raise Errno::EINVAL, 'Invalid argument - negative length' if length < 0

      assert_writable

      encoding = string.encoding
      string.force_encoding('binary')
      if length < string.bytesize
        string.slice!(length..-1)
      elsif length > string.bytesize
        string << "\0".b * (length - string.bytesize)
      end
      string.force_encoding(encoding)

      length
    end

    def unread(buffer, length: buffer.bytesize)
      assert_readable

      length = Integer(length)
      raise ArgumentError 'length must be at least 0' if length < 0

      return nil if length == 0

      replace_length = length
      @pos -= length
      if @pos < 0
        replace_length = length + @pos
        @pos = 0
      end

      encoding = string.encoding
      string.force_encoding('binary')
      pad_for_position
      string[@pos, replace_length] = buffer[0, length]
      string.force_encoding(encoding)

      nil
    rescue FrozenError
      raise IOError, 'not modifiable string'
    end

    def write(buffer, length: buffer.bytesize)
      assert_writable

      @pos = string.bytesize if @append

      string.force_encoding('binary')
      pad_for_position
      string[@pos, length] = buffer[0, length]
      string.force_encoding(encoding)
      @pos += length

      length
    rescue FrozenError
      raise IOError, 'not modifiable string'
    end
    alias_method :unbuffered_write, :write

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

  def initialize(string = '', mode = nil, **opt)
    if block_given?
      warn("#{self.class.name}::new() does not take block; use #{self.class.name}::open() instead")
    end

    string, opt = parse_init_args(string, mode, **opt)
    binmode = opt.delete(:binmode)
    encoding = opt[:encoding]

    super(
      StringWrapper.new(string, **opt),
      binmode: binmode,
      external_encoding: encoding
    )
  end

  def external_encoding
    result = super
    return nil if @in_set_encoding_by_bom
    result
  end

  def reopen(*args)
    assert_thawed

    if args.size == 1 && LikeStringIO === args[0]
      @delegate = args[0].delegate_r
      @delegate_w = @delegate
    else
      initialize(*args)
    end

    self
  end

  def set_encoding(*args)
    result = super
    delegate.encoding = external_encoding

    result
  end

  def set_encoding_by_bom
    rewind
    binmode = @binmode
    @binmode = true
    @in_set_encoding_by_bom = true
    super
  ensure
    @in_set_encoding_by_bom = false
    @binmode = binmode
  end

  def size
    assert_thawed

    delegate.string.bytesize
  end

  def string
    assert_thawed

    delegate.string
  end

  def string=(string)
    assert_thawed

    delegate.string = string
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

    delegate.truncate(length)
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
    string = String.new(string) unless String === string
    if ! (mode.nil? || opt[:mode].nil?)
      raise ArgumentError, 'mode specified twice'
    end
    mode = opt.delete(:mode) if mode.nil?

    decoded_mode = decode_mode(mode, string.frozen?)
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
    # Even though StringIO will complain if explicit encoding options are
    # included along with encodings set via the mode string, it always ignores
    # those explicit encoding options even if the mode string doesn't include
    # encodings itself.
    opt.delete(:encoding)
    opt.delete(:external_encoding)
    opt.delete(:internal_encoding)

    # The encoding defaults to the string's encoding if unspecified otherwise.
    decoded_mode[:encoding] ||= string.encoding

    return [string, opt.merge!(decoded_mode)]
  end

  ##
  # This overrides the handling of any buffer given to read operations to always
  # leave it in binary encoding, contrary to the behavior of real IO objects.
  def handle_buffer(length, buffer)
    unless buffer.nil?
      buffer.force_encoding(Encoding::ASCII_8BIT)

      # Ensure the given buffer is large enough to hold the requested number of
      # bytes because the delegate will not read more than the buffer given to
      # it can hold.
      buffer << "\0".b * (length - buffer.bytesize) if length > buffer.bytesize
    end

    result = yield

    unless buffer.nil?
      # A buffer was given to fill, so the delegate returned the number of bytes
      # read.  Truncate the buffer if necessary.
      buffer.slice!(result..-1)
    end

    result
  end
end

if $0 == __FILE__
end

# vim: ts=2 sw=2 et
