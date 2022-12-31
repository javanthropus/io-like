# frozen_string_literal: true

require 'io/like_helpers/buffered_io'
require 'io/like_helpers/duplexed_io'
require 'io/like_helpers/io'
require 'io/like_helpers/io_wrapper'
require 'io/like_helpers/ruby_facts'

##
# All the goodies for this library go in this namespace.  It's probably a bad
# idea.
class IO

##
# This is a wrapper class that provides the same instance methods as the IO
# class for simpler delegates given to it.
class Like < LikeHelpers::DuplexedIO
  include LikeHelpers::RubyFacts
  include Enumerable

  ##
  # This is used by #puts as the separator between all arguments.
  ORS = "\n".freeze

  ##
  # Creates a new instance of this class.
  #
  # @param delegate_r [LikeHelpers::BufferedIO] delegate for read operations
  # @param delegate_w [LikeHelpers::BufferedIO] delegate for write operations
  # @param autoclose [Boolean] when `true` close the delegate(s) when this
  #   stream is closed
  # @param binmode [Boolean] when `true` suppresses EOL <-> CRLF conversion on
  #   Windows and sets external encoding to ASCII-8BIT unless explicitly
  #   specified
  # @param internal_encoding [Encoding, String] the internal encoding
  # @param external_encoding [Encoding, String] the external encoding
  # @param encoding_opts [Hash] options to be passed to String#encode
  # @param sync [Boolean] when `true` causes write operations to bypass internal
  #   buffering
  # @param pid [Integer] the return value for {#pid}
  def initialize(
    delegate_r,
    delegate_w = delegate_r,
    autoclose: true,
    binmode: false,
    internal_encoding: nil,
    external_encoding: nil,
    encoding_opts: {},
    sync: false,
    pid: nil
  )
    super(delegate_r, delegate_w, autoclose: autoclose)

    @encoding_opts_r = {}
    @encoding_opts_w = {}

    # NOTE:
    # Binary mode must be set before the encoding in order to allow any
    # explicitly set external encoding to override the implicit ASCII-8BIT
    # encoding when binmode is set.
    @binmode = false
    self.binmode if binmode
    unless binmode && external_encoding.nil? && internal_encoding.nil?
      if ! (Encoding === external_encoding) && external_encoding =~ /^bom\|/i
        if set_encoding_by_bom.nil?
          set_encoding(external_encoding.to_s[4..-1], internal_encoding, encoding_opts)
        end
      else
        set_encoding(external_encoding, internal_encoding, encoding_opts)
      end
    end

    @pid = pid

    self.sync = sync

    @skip_duplexed_check = false
  end

  ##
  # Writes `obj` to the stream using {#write}.
  #
  # @param obj converted to a String using its #to_s method
  #
  # @return [self]
  def <<(obj)
    write(obj)
    self
  end

  ##
  # Puts the stream into binary mode.
  #
  # Once a stream is in binary mode, it cannot be reset to nonbinary mode.
  # * Newline conversion disabled
  # * Encoding conversion disabled
  # * Content is treated as ASCII-8BIT
  #
  # @return [self]
  #
  # @raise [IOError] if the stream is closed
  def binmode
    assert_open
    @binmode = true
    set_encoding(Encoding::ASCII_8BIT)
    self
  end

  ##
  # Returns `true` if the stream is in binary mode and `false` otherwise.
  #
  # @return [Boolean]
  #
  # @raise [IOError] if the stream is closed
  def binmode?
    assert_open
    @binmode
  end

  if RBVER_LT_3_0
  ##
  # @deprecated Use {#each_byte} instead.
  #
  # @version < Ruby 3.0
  def bytes(&block)
    warn('warning: IO#bytes is deprecated; use #each_byte instead')
    each_byte(&block)
  end

  ##
  # @deprecated Use {#each_char} instead.
  #
  # @version < Ruby 3.0
  def chars(&block)
    warn('warning: IO#chars is deprecated; use #each_char instead')
    each_char(&block)
  end
  end

  ##
  # Closes the stream, flushing any buffered data first.
  #
  # This always blocks when buffered data needs to be written, even when the
  # stream is in nonblocking mode.
  #
  # @return [nil]
  def close
    @skip_duplexed_check = true
    ensure_blocking { super }

    nil
  ensure
    @skip_duplexed_check = false
  end

  ##
  # Closes the read side of duplexed streams and closes the entire stream for
  # read-only, non-duplexed streams.
  #
  # @return [nil]
  #
  # @raise [IOError] if the stream is non-duplexed and writable
  def close_read
    return if closed_read?

    if ! @skip_duplexed_check && ! duplexed? && writable?
      raise IOError, 'closing non-duplex IO for reading'
    end

    ensure_blocking { super }

    nil
  end

  ##
  # Closes the write side of duplexed streams and closes the entire stream for
  # write-only, non-duplexed streams.
  #
  # @return [nil]
  #
  # @raise [IOError] if the stream is non-duplexed and readable
  def close_write
    return if closed_write?

    if ! @skip_duplexed_check && ! duplexed? && readable?
      raise IOError, 'closing non-duplex IO for writing'
    end

    flush if writable?
    ensure_blocking { super }

    nil
  end

  if RBVER_LT_3_0
  ##
  # @deprecated Use {#each_codepoint} instead.
  #
  # @version < Ruby 3.0
  def codepoints(&block)
    warn('warning: IO#codepoints is deprecated; use #each_codepoint instead')
    each_codepoint(&block)
  end
  end

  ##
  # @overload each_byte
  #   @return [Enumerator] an enumerator that iterates over each byte in the
  #     stream
  #
  # @overload each_byte
  #   Iterates over each byte in the stream, yielding each byte to the given
  #   block.
  #
  #   @yieldparam byte [Integer] the next byte from the stream
  #
  #   @return [self]
  #
  # @raise [IOError] if the stream is not open for reading
  def each_byte
    return to_enum(:each_byte) unless block_given?

    while (byte = getbyte) do
      yield(byte)
    end
    self
  end

  ##
  # @overload each_char
  #   @return [Enumerator] an enumerator that iterates over each character in
  #     the stream
  #
  # @overload each_char
  #   Iterates over each character in the stream, yielding each character to the
  #   given block.
  #
  #   @yieldparam char [String] the next character from the stream
  #
  #   @return [self]
  #
  # @raise [IOError] if the stream is not open for reading
  def each_char
    return to_enum(:each_char) unless block_given?

    while char = getc do
      yield(char)
    end
    self
  end

  ##
  # @overload each_codepoint
  #   @return [Enumerator] an enumerator that iterates over each Integer ordinal
  #     of each character in the stream
  #
  # @overload each_codepoint
  #   Iterates over each Integer ordinal of each character in the stream,
  #   yielding each ordinal to the given block.
  #
  #   @yieldparam codepoint [Integer] the Integer ordinal of the next character
  #     from the stream
  #
  #   @return [self]
  #
  # @raise [IOError] if the stream is not open for reading
  def each_codepoint
    return to_enum(:each_codepoint) unless block_given?

    each_char { |c| yield(c.codepoints[0]) }
    self
  end

  ##
  # @overload each_line(separator = $/, limit = nil, chomp: false)
  #   @param separator [String, nil] a non-empty String that separates each
  #     line, an empty String that equates to 2 or more successive newlines as
  #     the separator, or `nil` to indicate reading all remaining data
  #   @param limit [Integer, nil] an Integer limiting the number of bytes
  #     returned in each line or `nil` to indicate no limit
  #   @param chomp [Boolean] when `true` trailing newlines and carriage returns
  #     will be removed from each line
  #
  #   @return [Enumerator] an enumerator that iterates over each line in the
  #     stream
  #
  # @overload each_line(limit, chomp: false)
  #   @param limit [Integer] an Integer limiting the number of bytes returned in
  #     each line or `nil` to indicate no limit
  #   @param chomp [Boolean] when `true` trailing newlines and carriage returns
  #     will be removed from each line
  #
  #   @return [Enumerator] an enumerator that iterates over each line in the
  #     stream where each line is separated by `$/`
  #
  # @overload each_line(separator = $/, limit = nil, chomp: false)
  #   Iterates over each line in the stream, yielding each line to the given
  #   block.
  #
  #   @param separator [String, nil] a non-empty String that separates each
  #     line, an empty String that equates to 2 or more successive newlines as
  #     the separator, or `nil` to indicate reading all remaining data
  #   @param limit [Integer, nil] an Integer limiting the number of bytes
  #     returned in each line or `nil` to indicate no limit
  #   @param chomp [Boolean] when `true` trailing newlines and carriage returns
  #     will be removed from each line
  #
  #   @yieldparam line [String] a line from the stream
  #
  #   @return [self]
  #
  # @overload each_line(limit, chomp: false)
  #   Iterates over each line in the stream, where each line is separated by
  #   `$/`, yielding each line to the given block.
  #
  #   @param limit [Integer] an Integer limiting the number of bytes returned in
  #     each line or `nil` to indicate no limit
  #   @param chomp [Boolean] when `true` trailing newlines and carriage returns
  #     will be removed from each line
  #
  #   @yieldparam line [String] a line from the stream
  #
  #   @return [self]
  #
  # @raise [IOError] if the stream is not open for reading
  def each_line(sep_string = $/, limit = nil, chomp: false)
    unless block_given?
      return to_enum(:each_line, sep_string, limit, chomp: chomp)
    end

    begin
      sep_string = String.new(sep_string) unless sep_string.nil?
      limit = Integer(limit) unless limit.nil?
    rescue TypeError
      limit = Integer(sep_string)
      sep_string = $/
    end

    raise ArgumentError, 'invalid limit: 0 for each_line' if limit == 0

    while (line = gets(sep_string, limit, chomp: chomp)) do
      yield(line)
    end
    self
  end
  alias :each :each_line

  ##
  # Returns `true` if the end of the stream has been reached and `false`
  # otherwise.
  #
  # @note This method will block if reading the stream blocks.
  # @note This method relies on buffered operations, so using it in conjuction
  #   with {#sysread} will be complicated at best.
  #
  # @return [Boolean]
  #
  # @raise [IOError] if the stream is not open for reading
  def eof?
    if byte = getbyte
      ungetbyte(byte)
      return false
    end
    true
  end
  alias :eof :eof?

  ##
  # Returns the external encoding of the stream, if any.
  #
  # @return [Encoding] the Encoding object that represents the encoding of the
  #   stream
  # @return [nil] if the stream is writable and no encoding is specified
  #
  # @raise [IOError] if the stream is closed and Ruby version is less than 3.1
  def external_encoding
    assert_open if RBVER_LT_3_1

    return @external_encoding if ! @external_encoding.nil? || writable?
    return Encoding::default_external
  end

  ##
  # Flushes the internal write buffer to the underlying stream.
  #
  # Regardless of the blocking status of the stream or interruptions during
  # writing, this method will block until either all the data is flushed or
  # until an error is raised.
  #
  # @return [self]
  #
  # @raise [IOError] if the stream is not open for writing
  def flush
    assert_open

    ensure_blocking { delegate_w.flush }

    self
  end

  ##
  # Returns the next byte from the stream.
  #
  # @return [Integer] the next byte from the stream
  # @return [nil] if the end of the stream has been reached
  #
  # @raise [IOError] if the stream is not open for reading
  def getbyte
    readbyte
  rescue EOFError
    return nil
  end

  ##
  # Returns the next character from the stream.
  #
  # @return [String] the next character from the stream
  # @return [nil] if the end of the stream has been reached
  #
  # @raise [IOError] if the stream is not open for reading
  def getc
    readchar
  rescue EOFError
    nil
  end

  ##
  # Returns the next line from the stream.
  #
  # @overload gets(separator = $/, limit = nil, chomp: false)
  #
  #   @param separator [String, nil] a non-empty String that separates each
  #     line, an empty String that equates to 2 or more successive newlines as
  #     the separator, or `nil` to indicate reading all remaining data
  #   @param limit [Integer, nil] an Integer limiting the number of bytes
  #     returned in each line or `nil` to indicate no limit
  #   @param chomp [Boolean] when `true` trailing newlines and carriage returns
  #     will be removed from each line
  #
  #   @return [String] the next line in the stream
  #   @return [nil] if the end of the stream has been reached
  #
  # @overload gets(limit, chomp: false)
  #
  #   @param limit [Integer] an Integer limiting the number of bytes returned in
  #     each line or `nil` to indicate no limit
  #   @param chomp [Boolean] when `true` trailing newlines and carriage returns
  #     will be removed from each line
  #
  #   @return [String] the next line in the stream where the separator is `$/`
  #   @return [nil] if the end of the stream has been reached
  #
  # @raise [IOError] if the stream is not open for reading
  def gets(sep_string = $/, limit = nil, chomp: false)
    readline(sep_string, limit, chomp: chomp)
  rescue EOFError
    $_ = nil
    nil
  end

  ##
  # Returns the internal encoding of the stream, if any.
  #
  # @return [Encoding] the Encoding object that represents the encoding of the
  #   internal string conversion
  # @return [nil] if no encoding is specified
  #
  # @raise [IOError] if the stream is closed and Ruby version is less than 3.1
  def internal_encoding
    assert_open if RBVER_LT_3_1
    @internal_encoding
  end

  ##
  # For compatibility with `IO`.
  alias_method :isatty, :tty?

  ##
  # Returns the current line number of the stream.
  #
  # More accurately the number of times {#gets} is called on the stream and
  # returns a non-`nil` result, either explicitly or implicitly via methods such
  # as {#each_line}, {#readline}, {#readlines}, etc. is returned.  This may
  # differ from the number of lines if `$/` is changed from the default or if
  # {#gets} is called with a different separator.
  #
  # @return [Integer] the current line number of the stream
  #
  # @raise [IOError] if the stream is not open for reading
  def lineno
    assert_readable

    @lineno ||= 0
  end

  ##
  # Sets the current line number of the stream to the given value.  `$.` is
  # updated by the _next_ call to {#gets}.  If the object given is not an
  # Integer, it is converted to one using the `Integer` method.
  #
  # @return [Integer] the current line number of the stream
  #
  # @raise [IOError] if the stream is not open for reading
  def lineno=(integer)
    assert_readable

    @lineno = Integer(integer)
  end

  if RBVER_LT_3_0
  ##
  # @deprecated Use {#each_line} instead.
  #
  # @version < Ruby 3.0
  def lines(*args, &block)
    warn('warning: IO#lines is deprecated; use #each_line instead')
    each_line(*args, &block)
  end
  end

  ##
  # @return [Integer] the number of bytes that can be read without blocking or
  #   `0` if unknown
  #
  # @raise [IOError] if the stream is not open for reading
  def nread
    assert_readable
    ensure_blocking { delegate_r.nread }
  end

  ##
  # Returns the process ID of a child process associated with this stream, if
  # any.
  #
  # @return [Integer] a process ID
  # @return [nil] if there is no associated child process
  #
  # @raise [IOError] if the stream is closed
  def pid
    assert_open
    return @pid unless @pid.nil?
    super
  end

  ##
  # @note This method will block if writing the stream blocks and there is data
  #   in the write buffer.
  #
  # @return [Integer] the current byte offset of the stream
  #
  # @raise [IOError] if the stream is closed
  # @raise [Errno::ESPIPE] if the stream is not seekable
  def pos
    assert_open

    flush
    delegate.seek(0, IO::SEEK_CUR)
  end
  alias :tell :pos

  ##
  # Sets the position of the stream to the given byte offset.
  #
  # @param position [Integer] the byte offset to which the stream will be set
  #
  # @return [Integer] the given byte offset
  #
  # @raise [IOError] if the stream is closed
  # @raise [Errno::ESPIPE] if the stream is not seekable
  def pos=(position)
    seek(position, IO::SEEK_SET)
    position
  end

  ##
  # @note This method only exists for interface compatibility with IO#pread.
  #
  # @raise [NotImplementedError]
  def pread(maxlen, offset, buffer = nil)
    raise NotImplementedError
  end

  ##
  # Writes the given object(s), if any, to the stream using {#write}.
  #
  # If no objects are given, `$_` is written.  The field separator (`$,`) is
  # written between successive objects if it is not `nil`.  The output record
  # separator (`$\`) is written after all other data if it is not `nil`.
  #
  # @param args [Array<Object>] zero or more objects to write to the stream
  #
  # @return [nil]
  #
  # @raise [IOError] if the stream is not open for writing
  def print(*args)
    # NOTE:
    # Through Ruby 3.1, $_ is always nil on entry to a Ruby method.  This
    # assignment is kept in case that ever changes.
    args << $_ if args.empty?
    first_arg = true
    args.each do |arg|
      # Write a field separator before writing each argument after the first
      # one unless no field separator is specified.
      if first_arg
        first_arg = false
      else
        write($,)
      end

      write(arg)
    end

    # Write the output record separator if one is specified.
    write($\) unless $\.nil?
    nil
  end

  ##
  # Writes the String returned by calling `Kernel.sprintf` using the given
  # arguments.
  #
  # @param args [Array] arguments to pass to `Kernel.sprintf`
  #
  # @return [nil]
  #
  # @raise [IOError] if the stream is not open for writing
  def printf(*args)
    write(sprintf(*args))
    nil
  end

  ##
  # If _obj_ is a String, write the first character; otherwise, convert _obj_ to
  # an Integer using the `Integer` method and write the low order byte.
  #
  # @param obj [String, Numeric] the character to be written
  #
  # @return [obj] the given parameter
  #
  # @raise [TypeError] if `obj` is not a String nor convertable to a Numeric
  #   type
  # @raise [IOError] if the stream is not open for writing
  def putc(obj)
    char = case obj
           when String
             obj[0]
           else
             [Integer(obj)].pack('V')[0]
           end
    write(char)
    obj
  end

  ##
  # Writes the given object(s), if any, to the stream.
  #
  # Uses {#write} after converting objects to strings using their `to_s`
  # methods.  Unlike {#print}, Array instances are recursively processed.  The
  # record separator character (`$\`) is written after each object which does
  # not end with the record separator already.
  #
  # If no objects are given, a single record separator is written.
  #
  # @param args [Array<Object>] zero or more objects to write to the stream
  #
  # @return [nil]
  #
  # @raise [IOError] if the stream is not open for writing
  def puts(*args)
    # Write only the record separator if no arguments are given.
    if args.length == 0
      write(ORS)
      return
    end

    flatten_puts(args)
    nil
  end

  ##
  # @note This method only exists for interface compatibility with IO#pwrite.
  #
  # @raise [NotImplementedError]
  def pwrite(string, offset)
    raise NotImplementedError
  end

  ##
  # Reads data from the stream.
  #
  # If _length_ is specified as a positive integer, at most _length_ bytes are
  # returned.  Truncated data will occur if there is insufficient data left to
  # fulfill the request.  If the read starts at the end of data, `nil` is
  # returned.
  #
  # If _length_ is unspecified or `nil`, an attempt to return all remaining data
  # is made.  Partial data will be returned if a low-level error is raised after
  # some data is retrieved.  If no data would be returned at all, an empty
  # String is returned.
  #
  # If _buffer_ is specified, it will be converted to a String using its
  # `to_str` method if necessary and will be filled with the returned data if
  # any.
  #
  # @param length [Integer] the number of bytes to read
  # @param buffer [String] the location into which data will be stored
  #
  # @return [String] the data read from the stream
  # @return [nil] if _length_ is non-zero but no data is left in the stream
  #
  # @raise [ArgumentError] if _length_ is less than 0
  # @raise [IOError] if the stream is not open for reading
  def read(length = nil, buffer = nil)
    unless length.nil? || length >= 0
      raise ArgumentError, "negative length #{length} given"
    end
    buffer = buffer.to_str unless buffer.nil?

    assert_readable

    content = read_bytes(length)
    unless buffer.nil?
      orig_encoding = buffer.encoding
      buffer.replace(content)
      buffer.force_encoding(orig_encoding)
      content = buffer
    end
    if length.nil?
      # Encode and transcode the content if necessary.
      content.force_encoding(external_encoding || Encoding.default_external)
      unless internal_encoding.nil?
        content.encode!(internal_encoding, **encoding_opts_r)
      end
    end

    return nil if content.empty? && (length || 0) > 0
    return content
  end

  ##
  # Reads and returns at most _length_ bytes from the stream.
  #
  # If the internal read buffer is **not** empty, only the buffer is used, even
  # if less than _length_ bytes are available.  If the internal buffer **is**
  # empty, sets non-blocking mode via {#nonblock=} and then reads from the
  # underlying stream.
  #
  # @param length [Integer] the number of bytes to read
  # @param buffer [String] the location in which to store the data
  # @param exception [Boolean] when `true` causes this method to raise
  #   exceptions when no data is available; otherwise, symbols are returned
  #
  # @return [String] the data read from the stream
  # @return [:wait_readable, :wait_writable] if _exception_ is `false` and no
  #   data is available
  # @return [nil] if _exception_ is `false` and reading begins at the end of the
  #   stream
  #
  # @raise [EOFError] if reading begins at the end of the stream
  # @raise [IOError] if the stream is not open for reading
  # @raise [IO::EWOULDBLOCKWaitReadable, IO::EWOULDBLOCKWaitWritable] if
  #   _exception_ is `true` and no data is available
  # @raise [Errno::EBADF] if non-blocking mode is not supported
  # @raise [SystemCallError] if there are low level errors
  def read_nonblock(length, buffer = nil, exception: true)
    length = Integer(length)
    raise ArgumentError, 'length must be at least 0' if length < 0
    buffer = buffer.to_str unless buffer.nil?

    assert_readable

    return (buffer || String.new(''.b)) if length == 0

    result = ensure_buffer(length, buffer) do |binary_buffer|
      unless delegate_r.read_buffer_empty?
        break delegate_r.read(length, buffer: binary_buffer)
      end

      self.nonblock = true
      delegate_r.unbuffered_read(length, buffer: binary_buffer)
    end

    case result
    when String
      # This means that a buffer was not given and that the delegate returned a
      # buffer with the content.
      return result
    when Integer
      # This means that a buffer was given and that the content is in the
      # buffer.
      return buffer
    else
      return nonblock_response(result, exception)
    end
  rescue EOFError
    raise if exception
    return nil
  end

  ##
  # @return [Integer] the next 8-bit byte (0..255) from the stream
  #
  # @raise [EOFError] if reading begins at the end of the stream
  # @raise [IOError] if the stream is not open for reading
  def readbyte
    assert_readable

    byte = ensure_blocking { delegate_r.read(1) }
    byte[0].ord
  end

  ##
  # @return [String] the next character from the stream
  #
  # @raise [EOFError] if reading begins at the end of the stream
  # @raise [IOError] if the stream is not open for reading
  def readchar
    assert_readable

    ext_enc = external_encoding || Encoding.default_external
    buffer = String.new('', encoding: ext_enc)

    begin
      loop do
        buffer << ensure_blocking { delegate_r.read(1) }.force_encoding(ext_enc)
        break if buffer.valid_encoding? || buffer.bytesize >= 16
      end
    rescue EOFError
      raise if buffer.empty?
    end
    char = buffer[0]
    ungetbyte(buffer[1..-1].b)

    unless internal_encoding.nil?
      char.encode!(internal_encoding, **encoding_opts_r)
    end

    char
  end

  ##
  # Returns the next line from the stream.
  #
  # @overload readline(separator = $/, limit = nil, chomp: false)
  #
  #   @param separator [String, nil] a non-empty String that separates each
  #     line, an empty String that equates to 2 or more successive newlines as
  #     the separator, or `nil` to indicate reading all remaining data
  #   @param limit [Integer, nil] an Integer limiting the number of bytes
  #     returned in each line or `nil` to indicate no limit
  #   @param chomp [Boolean] when `true` trailing newlines and carriage returns
  #     will be removed from each line
  #
  #   @return [String] the next line in the stream
  #
  # @overload readline(limit, chomp: false)
  #
  #   @param limit [Integer] an Integer limiting the number of bytes returned in
  #     each line or `nil` to indicate no limit
  #   @param chomp [Boolean] when `true` trailing newlines and carriage returns
  #     will be removed from each line
  #
  #   @return [String] the next line in the stream where the separator is `$/`
  #
  # @raise [EOFError] if reading begins at the end of the stream
  # @raise [IOError] if the stream is not open for reading
  def readline(sep_string = $/, limit = nil, chomp: false)
    begin
      sep_string = String.new(sep_string) unless sep_string.nil?
      limit = Integer(limit) unless limit.nil?
    rescue TypeError
      limit = Integer(sep_string)
      sep_string = $/
    end

    assert_readable

    ext_enc = external_encoding || Encoding.default_external
    int_enc = internal_encoding || ext_enc
    buffer = String.new('', encoding: int_enc)

    unless sep_string.nil?
      if sep_string.empty?
        paragraph_requested = true
        newline = "\n".encode(int_enc)
        sep_string = newline * 2
      else
        sep_string = sep_string.encode(int_enc)
      end
    end

    begin
      if paragraph_requested
        while (char = readchar) == newline do; end
        ungetc(char)
      end

      until (! sep_string.nil? && buffer.end_with?(sep_string)) ||
            (! limit.nil? &&
             (buffer.bytesize >= limit + 16 ||
              (buffer.bytesize >= limit && buffer.valid_encoding?)))
        buffer << readchar
      end

      if paragraph_requested
        while (char = readchar) == newline do; end
        ungetc(char)
      end
    rescue EOFError
      raise if buffer.empty?
    end

    if chomp
      if sep_string.nil? && limit.nil? && RBVER_LT_3_2
        buffer.chomp!
      else
        buffer.chomp!(sep_string)
      end
    end

    # Increment the number of times this method has returned a "line".
    self.lineno += 1
    # Set the last line number in the global.
    $. = lineno
    # Set the last read line in the global and return it.
    # NOTE:
    # Through Ruby 3.1, assigning to $_ has no effect outside of a method that
    # does it.  This assignment is kept in case that ever changes.
    $_ = buffer
  end

  ##
  # @overload readlines(separator = $/, limit = nil, chomp: false)
  #
  #   @param separator [String, nil] a non-empty String that separates each
  #     line, an empty String that equates to 2 or more successive newlines as
  #     the separator, or `nil` to indicate reading all remaining data
  #   @param limit [Integer, nil] an Integer limiting the number of bytes
  #     returned in each line or `nil` to indicate no limit
  #   @param chomp [Boolean] when `true` trailing newlines and carriage returns
  #     will be removed from each line
  #
  #   @return [Array<String>] the remaining lines in the stream
  #
  # @overload readlines(limit, chomp: false)
  #
  #   @param limit [Integer] an Integer limiting the number of bytes returned in
  #     each line or `nil` to indicate no limit
  #   @param chomp [Boolean] when `true` trailing newlines and carriage returns
  #     will be removed from each line
  #
  #   @return [Array<String>] the remaining lines in the stream where the
  #     separator is `$/`
  #
  # @raise [IOError] if the stream is not open for reading
  def readlines(sep_string = $/, limit = nil, chomp: false)
    each_line(sep_string, limit, chomp: chomp).to_a
  end

  ##
  # Reads and returns at most _length_ bytes from the stream.
  #
  # If the internal read buffer is **not** empty, only the buffer is used, even
  # if less than _length_ bytes are available.  If the internal buffer **is**
  # empty, reads from the underlying stream.
  #
  # @param length [Integer] the number of bytes to read
  # @param buffer [String] the location in which to store the data
  #
  # @return [String] the data read from the stream
  #
  # @raise [EOFError] if reading begins at the end of the stream
  # @raise [IOError] if the stream is not open for reading
  def readpartial(length, buffer = nil)
    length = Integer(length)
    raise ArgumentError, 'length must be at least 0' if length < 0
    buffer = buffer.to_str unless buffer.nil?

    assert_readable

    if RBVER_LT_3_1 && length == 0
      return (buffer || String.new(''.b))
    end

    result = ensure_buffer(length, buffer) do |binary_buffer|
      unless delegate_r.read_buffer_empty?
        break delegate_r.read(length, buffer: binary_buffer)
      end

      ensure_blocking do
        delegate_r.unbuffered_read(length, buffer: binary_buffer)
      end
    end

    # The delegate returns the read content unless a buffer is given.
    return buffer.nil? ? result : buffer
  end

  ##
  # @overload reopen(other)
  #   @param other [Like] another IO::Like instance whose delegate(s) will be
  #     dup'd and used as this stream's delegate(s)
  #
  #   @raise [IOError] if this instance is closed
  #
  # @overload reopen(io)
  #   @param io [IO, #to_io] an IO instance that will be dup'd and used as this
  #     stream's delegate
  #
  #   @raise [IOError] if this instance or _io_ are closed
  #
  # @overload reopen(path, mode, **opt)
  #   @param path [String] path to a file to open and use as a delegate for this
  #     stream
  #   @param mode [String] file open mode as used by `File.open`, defaults to a
  #     mode equivalent to this stream's current read/writ-ability
  #   @param opts [Hash] options hash as used by `File.open`
  #
  #   @raise all errors raised by `File.open`
  #
  # Replaces the delegate(s) of this stream with another instance's delegate(s)
  # or an IO instance.
  #
  # @return [self]
  def reopen(*args, **opts)
    unless args.size == 1 || args.size == 2
      raise ArgumentError,
        "wrong number of arguments (given #{args.size}, expected 1..2)"
    end

    if args.size == 1
      begin
        io = args[0]
        io = args[0].to_io unless IO::Like === io

        if IO::Like === io
          assert_open
          close
          @delegate = io.delegate_r.dup
          @delegate_w = io.duplexed? ? io.delegate_w.dup : delegate_r
          @closed = @closed_write = false
          return self
        end

        unless IO === io
          raise TypeError,
            "can't convert #{args[0].class} to IO (#{args[0].class}#to_io gives #{io.class})"
        end

        assert_open
        io = io.dup
      rescue NoMethodError
        mode = String.new(readable? ? 'r' : 'w')
        mode << '+' if readable? && writable?
        mode << 'b'
        io = File.open(args[0], mode)
      end
    else
      io = File.open(*args, **opts)
    end

    io = IO::LikeHelpers::BufferedIO.new(IO::LikeHelpers::IOWrapper.new(io))
    close
    @delegate = @delegate_w = io
    @closed = @closed_write = false

    self
  end

  ##
  # Sets the position of the file pointer to the beginning of the stream.
  #
  # The `lineno` attribute is reset to `0` if successful and the stream is
  # readable.
  #
  # @return [0]
  #
  # @raise [IOError] if the stream is closed
  # @raise [Errno::ESPIPE] if the stream is not seekable
  def rewind
    seek(0, IO::SEEK_SET)
    self.lineno = 0 if readable?
    0
  end

  ##
  # Sets the current stream position to _amount_ based on the setting of
  # _whence_.
  #
  # | _whence_ | _amount_ Interpretation |
  # | -------- | ----------------------- |
  # | `:CUR` or `IO::SEEK_CUR` | _amount_ added to current stream position |
  # | `:END` or `IO::SEEK_END` | _amount_ added to end of stream position (_amount_ will usually be negative here) |
  # | `:SET` or `IO::SEEK_SET` | _amount_ used as absolute position |
  #
  # @param amount [Integer] the amount to move the position in bytes
  # @param whence [Integer, Symbol] the position alias from which to consider
  #   _amount_
  #
  # @return [0]
  #
  # @raise [IOError] if the stream is closed
  # @raise [Errno::ESPIPE] if the stream is not seekable
  def seek(amount, whence = IO::SEEK_SET)
    super
    0
  end

  ##
  # @overload set_encoding(encoding, **opts)
  #   @param encoding [Encoding, String, nil] the external encoding or both the
  #     external and internal encoding if specified as `"ext_enc:int_enc"`
  #   @param opts [Hash] encoding conversion options used if both internal and
  #     external encodings are specified
  #
  # @overload set_encoding(external, internal, **opts)
  #   @param external [Encoding, String, nil] the external encoding
  #   @param internal [Encoding, String, nil] the internal encoding
  #   @param opts [Hash] encoding conversion options used if both internal and
  #     external encodings are specified
  #
  # Sets the external and internal encodings of the stream.
  #
  # When the given external encoding is not `nil` or `Encoding::BINARY` or an
  # equivalent and the internal encoding is either not given or `nil`, the
  # current value of `Encoding.default_internal` is used for the internal
  # encoding.
  #
  # When the given external encoding is `nil` and the internal encoding is either
  # not given or `nil`, the current values of `Encoding.default_external` and
  # `Encoding.default_internal` are used, respectively, unless
  # `Encoding.default_external` is `Encoding::BINARY` or an equivalent **or**
  # `Encoding.default_internal` is `nil`, in which case `nil` is used for both.
  #
  # Setting the given internal encoding to `"-"` indicates no character
  # conversion should be performed.  The internal encoding of the stream will be
  # set to `nil`.  This is needed in cases where `Encoding.default_internal` is
  # not `nil` but character conversion is not desired.
  #
  # @return [self]
  #
  # @raise [TypeError] if the given external encoding is `nil` and the internal
  #   encoding is given and **not** `nil`
  # @raise [ArgumentError] if an encoding given as a string is invalid
  def set_encoding(*args)
    assert_open

    # Pull out the last argument if it's an options hash.
    opts = Hash === args.last ? args.pop : {}

    # Check for the correct number of arguments.
    if args.size < 1
      raise ArgumentError, "wrong number of arguments (#{args.size} for 1)"
    elsif args.size > 2
      raise ArgumentError, "wrong number of arguments (#{args.size} for 2)"
    end

    # Check that any given newline option is valid.
    if opts.key?(:newline) &&
      ! %i{cr lf crlf universal}.include?(opts[:newline])
      message = 'unexpected value for newline option'
      message += ": #{opts[:newline]}" if Symbol === opts[:newline]
      raise ArgumentError, message
    end

    # Newline handling is not allowed in binary mode.
    if binmode? &&
      (opts.key?(:newline) && opts[:newline] != :lf ||
       opts[:cr_newline] || opts[:crlf_newline] || opts[:universal])
      raise ArgumentError, 'newline decorator with binary mode'
    end

    # Convert the argument(s) into Encoding objects.
    if ! (args[0].nil? || Encoding === args[0]) && args[1].nil?
      string_arg = String.new(args[0])
      begin
        split_idx = string_arg.rindex(':')
        unless split_idx.nil? || split_idx == 0
          args[0] = string_arg[0...split_idx]
          args[1] = string_arg[(split_idx + 1)..-1]
        end
      rescue Encoding::CompatibilityError
        # This is caused by failure to split on colon when the string argument
        # is not ASCII compatible.  Ignore it and use the argument as is.
      end
    end
    ext_enc, int_enc = args

    # Potential values:
    # ext_enc        int_enc
    # ======================
    # nil            Object    => error
    # nil            nil       => maybe copy default encodings
    # Object         Object    => use given encodings
    # Object         nil       => maybe copy default internal encoding
    if ext_enc.nil? && int_enc.nil?
      unless Encoding.default_external == Encoding::BINARY ||
             Encoding.default_internal.nil?
        ext_enc = Encoding.default_external
        int_enc = Encoding.default_internal
      end
    else
      ext_enc = Encoding.find(ext_enc)
      int_enc = case int_enc
                when nil
                  Encoding.default_internal
                when '-'
                  # Allows explicit request of no conversion when
                  # Encoding.default_internal is set.
                  nil
                else
                  Encoding.find(int_enc)
                end
    end
    # Ignore the chosen internal encoding when no conversion will be performed.
    int_enc = nil if int_enc == ext_enc || ext_enc == Encoding::BINARY

    @external_encoding = ext_enc
    @internal_encoding = int_enc
    self.encoding_opts_r = opts
    self.encoding_opts_w = opts

    self
  end

  ##
  # Sets the external encoding of the stream based on a byte order mark (BOM)
  # in the next bytes of the stream if found or to `nil` if not found.
  #
  # @return [nil] if no byte order mark is found
  # @return [Encoding] the encoding indicated by the byte order mark
  #
  # @raise [ArgumentError] if the stream is not in binary mode, an internal
  #   encoding is set, or the external encoding is set to anything other than
  #   `Encoding::BINARY`
  #
  # @version \>= Ruby 2.7
  def set_encoding_by_bom
    unless binmode?
      raise ArgumentError, 'ASCII incompatible encoding needs binmode'
    end
    if ! internal_encoding.nil?
      raise ArgumentError, 'encoding conversion is set'
    elsif ! (external_encoding.nil? || external_encoding == Encoding::BINARY)
      raise ArgumentError, "encoding is set to #{external_encoding} already"
    end

    return nil unless readable?

    case b1 = getbyte
    when nil
    when 0xEF
      case b2 = getbyte
      when nil
      when 0xBB
        case b3 = getbyte
        when nil
        when 0xBF
          set_encoding(Encoding::UTF_8)
          return Encoding::UTF_8
        end
        ungetbyte(b3)
      end
      ungetbyte(b2)
    when 0xFE
      case b2 = getbyte
      when nil
      when 0xFF
        set_encoding(Encoding::UTF_16BE)
        return Encoding::UTF_16BE
      end
      ungetbyte(b2)
    when 0xFF
      case b2 = getbyte
      when nil
      when 0xFE
        case b3 = getbyte
        when nil
        when 0x00
          case b4 = getbyte
          when nil
          when 0x00
            set_encoding(Encoding::UTF_32LE)
            return Encoding::UTF_32LE
          end
          ungetbyte(b4)
        end
        ungetbyte(b3)
        set_encoding(Encoding::UTF_16LE)
        return Encoding::UTF_16LE
      end
      ungetbyte(b2)
    when 0x00
      case b2 = getbyte
      when nil
      when 0x00
        case b3 = getbyte
        when nil
        when 0xFE
          case b4 = getbyte
          when nil
          when 0xFF
            set_encoding(Encoding::UTF_32BE)
            return Encoding::UTF_32BE
          end
          ungetbyte(b4)
        end
        ungetbyte(b3)
      end
      ungetbyte(b2)
    end
    ungetbyte(b1)

    return nil
  end

  ##
  # Returns `true` if the internal write buffer is being bypassed and `false`
  # otherwise.
  #
  # @return [Boolean]
  #
  # @raise [IOError] if the stream is closed
  def sync
    assert_open
    @sync ||= false
  end

  ##
  # When set to `true` the internal write buffer will be bypassed.  Any data
  # currently in the buffer will be flushed prior to the next output operation.
  # When set to `false`, the internal write buffer will be enabled.
  #
  # @param sync [Boolean] the sync mode
  #
  # @return [Boolean] the given value for _sync_
  #
  # @raise [IOError] if the stream is closed
  def sync=(sync)
    assert_open
    @sync = sync ? true : false
  end

  ##
  # Reads and returns up to _length_ bytes directly from the data stream,
  # bypassing the internal read buffer.
  #
  # If _buffer_ is given, it is used to store the bytes that are read;
  # otherwise, a new buffer is created.
  #
  # Returns an empty String if _length_ is `0` regardless of the status of the
  # data stream.  This is for compatibility with `IO#sysread`.
  #
  # @param length [Integer] the number of bytes to read
  # @param buffer [String] a buffer into which bytes will be read
  #
  # @return [String] the bytes that were read
  #
  # @raise [EOFError] if reading begins at the end of the stream
  # @raise [IOError] if the internal read buffer is not empty
  # @raise [IOError] if the stream is not open for reading
  def sysread(length, buffer = nil)
    length = Integer(length)
    raise ArgumentError, "negative length #{length} given" if length < 0
    buffer = buffer.to_str unless buffer.nil?

    return (buffer || String.new(''.b)) if length == 0

    assert_readable

    unless delegate_r.read_buffer_empty?
      raise IOError, 'sysread for buffered IO'
    end

    result = ensure_buffer(length, buffer) do |binary_buffer|
      ensure_blocking do
        delegate_r.unbuffered_read(length, buffer: binary_buffer)
      end
    end

    # The delegate returns the read content unless a buffer is given.
    return buffer.nil? ? result : buffer
  end

  ##
  # Sets the current, unbuffered stream position to _amount_ based on the
  # setting of _whence_.
  #
  # | _whence_ | _amount_ Interpretation |
  # | -------- | ----------------------- |
  # | `:CUR` or `IO::SEEK_CUR` | _amount_ added to current stream position |
  # | `:END` or `IO::SEEK_END` | _amount_ added to end of stream position (_amount_ will usually be negative here) |
  # | `:SET` or `IO::SEEK_SET` | _amount_ used as absolute position |
  #
  # @param offset [Integer] the amount to move the position in bytes
  # @param whence [Integer, Symbol] the position alias from which to consider
  #   _amount_
  #
  # @return [Integer] the new stream position
  #
  # @raise [IOError] if the internal read buffer is not empty
  # @raise [IOError] if the stream is closed
  # @raise [Errno::ESPIPE] if the stream is not seekable
  def sysseek(offset, whence = IO::SEEK_SET)
    assert_open
    unless delegate_r.read_buffer_empty?
      raise IOError, 'sysseek for buffered IO'
    end
    unless delegate_w.write_buffer_empty?
      warn('warning: sysseek for buffered IO')
    end

    delegate.unbuffered_seek(offset, whence)
  end

  ##
  # Writes _string_ directly to the data stream, bypassing the internal
  # write buffer.
  #
  # @param string [String] a string of bytes to be written
  #
  # @return [Integer] the number of bytes written
  #
  # @raise [IOError] if the stream is not open for writing
  def syswrite(string)
    assert_writable
    unless delegate_w.write_buffer_empty?
      warn('warning: syswrite for buffered IO')
    end

    if RBVER_LT_3_2
      result = delegate_w.flush || delegate_w.unbuffered_write(string.to_s.b)
      if Symbol === result
        raise Errno::EWOULDBLOCK if RBPLAT_IS_WINDOWS
        raise Errno::EAGAIN
      end
      result
    else
      ensure_blocking do
        delegate_w.flush || delegate_w.unbuffered_write(string.to_s.b)
      end
    end
  end

  ##
  # This is for compatibility with IO.
  alias_method :to_i, :fileno

  ##
  # @overload ungetbyte(string)
  #   @param string [String] a string of bytes to push onto the internal read
  #     buffer
  #
  # @overload ungetbyte(integer)
  #   @param integer [Integer] a number whose low order byte will be pushed
  #     onto the internal read buffer
  #
  # Pushes bytes onto the internal read buffer such that subsequent read
  # operations will return them first.
  #
  # @return [nil]
  #
  # @raise [IOError] if the stream is not open for reading
  # @raise [IOError] if the internal read buffer does not have enough space
  def ungetbyte(obj)
    assert_readable

    return if obj.nil?

    string = case obj
             when String
               obj
             when Integer
               (obj & 255).chr
             else
               String.new(obj)
             end
    result = delegate.unread(string.b)
    result
  end

  ##
  # @overload ungetc(string)
  #   @param string [String] a string of characters to push onto the internal
  #     read buffer
  #
  # @overload ungetc(integer)
  #   @param integer [Integer] a number that will be converted into a character
  #     using the stream's external encoding and pushed onto the internal read
  #     buffer
  #
  # Pushes characters onto the internal read buffer such that subsequent read
  # operations will return them first.
  #
  # @return [nil]
  #
  # @raise [IOError] if the stream is not open for reading
  # @raise [IOError] if the internal read buffer does not have enough space
  def ungetc(string)
    assert_readable

    return if string.nil? && RBVER_LT_3_0

    string = case string
             when String
               string
             when Integer
               string.chr(external_encoding)
             else
               String.new(string)
             end
    result = delegate.unread(string.b)
    result
  end

  ##
  # @overload wait(events, timeout)
  #   @param events [Integer] a bit mask of `IO::READABLE`, `IO::WRITABLE`, or
  #     `IO::PRIORITY`
  #   @param timeout [Numeric, nil] the timeout in seconds or no timeout if
  #     `nil`
  #
  # @overload wait(timeout = nil, mode = :read)
  #   @param timeout [Numeric]
  #   @param mode [Symbol]
  #
  #   @deprecated Included for compability with Ruby 2.7 and earlier
  #
  # @return [self] if the stream becomes ready for at least one of the given
  #   events
  # @return [nil] if the IO does not become ready before the timeout
  #
  # @raise [IOError] if the stream is closed
  def wait(*args)
    events = 0
    timeout = nil
    if RBVER_LT_3_0
      # Ruby <=2.7 compatibility mode while running Ruby <=2.7.
      args.each do |arg|
        case arg
        when Symbol
          events |= wait_event_from_symbol(arg)
        else
          timeout = arg
          unless timeout.nil? || timeout >= 0
            raise ArgumentError, 'time interval must not be negative'
          end
        end
      end
    else
      if args.size < 2 || args.size >= 2 && Symbol === args[1]
        # Ruby <=2.7 compatibility mode while running Ruby >=3.0.
        timeout = args[0] if args.size > 0
        unless timeout.nil? || timeout >= 0
          raise ArgumentError, 'time interval must not be negative'
        end
        events = args[1..-1]
          .map { |mode| wait_event_from_symbol(mode) }
          .inject(0) { |memo, value| memo | value }
      elsif args.size == 2
        # Ruby >=3.0 mode.
        events = Integer(args[0])
        timeout = args[1]
        unless timeout.nil? || timeout >= 0
          raise ArgumentError, 'time interval must not be negative'
        end
      else
        # Arguments are invalid, but punt like Ruby 3.0 does.
        return nil
      end
    end
    events = IO::READABLE if events == 0

    assert_open

    return self if super(events, timeout)
    return nil
  end

  unless RBVER_LT_3_0
  ##
  # Waits until the stream is priority or until `timeout` is reached.
  #
  # Returns `true` immediately if buffered data is available to read.
  #
  # @return [self] when the stream is priority
  # @return [nil] when the call times out
  #
  # @raise [IOError] if the stream is not open for reading
  #
  # @version \>= Ruby 3.0
  def wait_priority(timeout = nil)
    assert_readable

    return self if delegate.wait(IO::PRIORITY, timeout)
    return nil
  end
  end

  ##
  # Waits until the stream is readable or until `timeout` is reached.
  #
  # Returns `true` immediately if buffered data is available to read.
  #
  # @return [self] when the stream is readable
  # @return [nil] when the call times out
  #
  # @raise [IOError] if the stream is not open for reading
  def wait_readable(timeout = nil)
    assert_readable

    return self if delegate.wait(IO::READABLE, timeout)
    return nil
  end

  ##
  # Waits until the stream is writable or until `timeout` is reached.
  #
  # @return [self] when the stream is writable
  # @return [nil] when the call times out
  #
  # @raise [IOError] if the stream is not open for writing
  def wait_writable(timeout = nil)
    assert_writable

    return self if delegate.wait(IO::WRITABLE, timeout)
    return nil
  end

  ##
  # Writes the given arguments to the stream via an internal buffer and returns
  # the number of bytes written.
  #
  # If an argument is not a `String`, its `to_s` method is used to convert it
  # into one.  The entire contents of all arguments are written, blocking as
  # necessary even if the underlying stream does not block.
  #
  # @param strings [Array<Object>] bytes to write to the stream
  #
  # @return [Integer] the total number of bytes written
  #
  # @raise [IOError] if the stream is not open for writing
  def write(*strings)
    # This short circuit is for compatibility with old Ruby versions where this
    # method took a single argument and would return 0 when the argument
    # resulted in a 0 length string without first checking if the stream was
    # already closed.
    if strings.size == 1
      # This satisfies rubyspec by ensuring that the argument's #to_s method is
      # only called once in the case where it results in a non-empty string and
      # the short circuit is skipped.
      strings[0] = strings[0].to_s
      return 0 if strings[0].empty?
    end

    assert_writable

    strings.map!(&:to_s)

    total_bytes_written = 0

    flush if sync
    strings.each do |string|
      unless binmode?
        # Convert to the external encoding if possible, ignoring errors.
        begin
          string = string.encode(
            external_encoding || string.encoding,
            **encoding_opts_w
          )
        rescue Encoding::UndefinedConversionError
        end
      end

      buffer = string.b
      bytes_written = 0
      while bytes_written < buffer.bytesize do
        bytes_written += ensure_blocking do
          sync ?
            delegate_w.unbuffered_write(buffer[bytes_written..-1]) :
            delegate_w.write(buffer[bytes_written..-1])
        end
      end
      total_bytes_written += bytes_written
    end

    total_bytes_written
  end

  ##
  # Enables blocking mode on the stream (via #nonblock=), flushes any buffered
  # data, and then directly writes _string_, bypassing the internal buffer.
  #
  # If _string_ is not a `String`, its `to_s` method is used to convert it into
  # one.  If any of _string_ is written, this method returns the number of bytes
  # written, which may be less than all requested bytes (partial write).
  #
  # @param string [Object] bytes to write to the stream
  # @param exception [Boolean] when `true` causes this method to raise
  #   exceptions when writing would block; otherwise, symbols are returned
  #
  # @return [Integer] the total number of bytes written
  # @return [:wait_readable, :wait_writable] if _exception_ is `false` and
  #   writing to the stream would block
  #
  # @raise [IOError] if the stream is not open for writing
  # @raise [IO::EWOULDBLOCKWaitReadable, IO::EWOULDBLOCKWaitWritable] if
  #   _exception_ is `true` and writing to the stream would block
  # @raise [Errno::EBADF] if non-blocking mode is not supported
  # @raise [SystemCallError] if there are low level errors
  def write_nonblock(string, exception: true)
    assert_writable

    string = string.to_s

    self.nonblock = true
    result = delegate_w.flush || delegate_w.unbuffered_write(string.b)
    case result
    when Integer
      return result
    else
      return nonblock_response(result, exception)
    end
  end

  # Expose these to other instances of this class for use with #reopen.
  protected :delegate_r, :delegate_w

  # Hide these to preserve the interface of IO.
  private :readable?, :writable?

  private

  ##
  # Sets the encoding options for reading.
  #
  # @return _opts_
  def encoding_opts_r=(opts)
    # Ruby obeys only the universal newline decoration for reading.
    @encoding_opts_r.merge!(
      opts.reject do |k, v|
        k == :crlf_newline || k == :cr_newline ||
          (k == :newline && (v == :crlf || v == :cr || v == :lf))
      end
    )

    opts
  end

  ##
  # The encoding options for reading.
  attr_reader :encoding_opts_r

  ##
  # Sets the encoding options for writing.
  #
  # @return _opts_
  def encoding_opts_w=(opts)
    # Ruby ignores the universal newline decoration for writing.
    @encoding_opts_w.merge!(
      opts.reject do |k, v|
        k == :universal_newline || (k == :newline && v == :universal)
      end
    )

    opts
  end

  ##
  # The encoding options for writing.
  attr_reader :encoding_opts_w

  ##
  # Runs the given block in a wait loop that exits only when the block returns a
  # non-Symbol value.
  #
  # This method is intended to wrap an IO operation that may be non-blocking and
  # effectively turn it into a blocking operation without changing underlying
  # settings of the stream itself.
  #
  # @return the return value of the block if not a Symbol
  #
  # @raise [RuntimeError] if the Symbol returned by the block is neither
  #   `:wait_readable` nor `:wait_writable`
  def ensure_blocking
    begin
      while Symbol === (result = yield) do
        # A wait timeout is used in order to allow a retry in case the stream was
        # closed in another thread while waiting.
        case result
        when :wait_readable
          wait_readable(1)
        when :wait_writable
          wait_writable(1)
        else
          raise "Unexpected result: #{result}"
        end
      end
    rescue Errno::EINTR
      retry
    end

    result
  end

  ##
  # Ensures that a buffer, if provided, is large enough to hold the requested
  # number of bytes and is then truncated to the returned number of bytes while
  # ensuring that the encoding is preserved.
  #
  # @param length [Integer] the minimum size of the buffer in bytes
  # @param buffer [String, nil] the buffer
  #
  # @yieldparam binary_buffer [String, nil] a binary encoded String based on
  #   `buffer` (if non-nil) that is at least `length` bytes long
  # @yieldreturn [Integer, String, Symbol] the result of a low level read
  #   operation. (See {IO::LikeHelpers::AbstractIO#read})
  #
  # @return the result of the given block
  def ensure_buffer(length, buffer)
    unless buffer.nil?
      orig_encoding = buffer.encoding
      buffer.force_encoding(Encoding::ASCII_8BIT)

      # Ensure the given buffer is large enough to hold the requested number of
      # bytes.
      buffer << "\0".b * (length - buffer.bytesize) if length > buffer.bytesize
    end

    result = yield(buffer)
  ensure
    unless buffer.nil?
      # A buffer was given to fill, so the delegate returned the number of bytes
      # read.  Truncate the buffer if necessary and restore its original
      # encoding.
      buffer.slice!((result || 0)..-1)
      buffer.force_encoding(orig_encoding)
    end
  end

  ##
  # Write `item` followed by the record separator.  Recursively process
  # elements of `item` if it responds to `#to_ary` with a non-`nil` result.
  #
  # @param item [Object] the item to be `String`-ified and written to the stream
  # @param seen [Array] a list of `Objects` that have already been printed
  #
  # @return [nil]
  def flatten_puts(item, seen = [])
    if seen.include?(item.object_id)
      write('[...]')
      write(ORS)
      return
    end

    seen.push(item.object_id)

    array = item.to_ary rescue nil
    if array.nil?
      string = item.to_s
      unless String === string
        # This ensures that #inspect-like output is generated even if item
        # implments its own #inspect implementation.
        #
        # NOTE:
        # This seems to work even for decendents of BasicObject even though
        # Object is not part of the ancestry of BasicObject and thus
        # Object#inspect should not be bindable to classes that decend more
        # directly from BasicObject.  IOW, this may only work as side effect of
        # Ruby VM implementation in such cases.
        string =
          Object.new.method(:inspect).unbind.bind(item)[].split(' ')[0] + '>'
      end
      write(string)
      write(ORS) unless string.end_with?(ORS)
    else
      array.each { |i| flatten_puts(i, seen) }
    end

    seen.pop

    nil
  end

  ##
  # Converts non-blocking responses into exceptions if requested.
  #
  # @param type [:wait_readable, :wait_writable] the type of non-blocking
  #   response
  # @param exception [Boolean] if `true`, raise an exception for `type`
  #
  # @return [:wait_readable, :wait_writable] if `exception` is `false`
  def nonblock_response(type, exception)
    case type
    when :wait_readable
      return type unless exception
      raise IO::EWOULDBLOCKWaitReadable
    when :wait_writable
      return type unless exception
      raise IO::EWOULDBLOCKWaitWritable
    else
      raise ArgumentError, "Invalid type: #{type}"
    end
  end

  ##
  # Reads and returns up to `length` bytes from this stream.
  #
  # This method always blocks, even when the stream is in non-blocking mode.  An
  # empty `String` is returned if reading begins at the end of the stream.
  #
  # @param length [Integer] the number of bytes to read
  #
  # @return [String] up to `length` bytes read from this stream
  def read_bytes(length)
    buffers = []
    remaining = length.nil? ? 8192 : length

    unless delegate_r.read_buffer_empty?
      buffers << delegate_r.read(remaining)
      remaining -= buffers[0].bytesize unless length.nil?
    end

    begin
      delegate_r.flush
      while remaining > 0 do
        bytes = ensure_blocking { delegate_r.unbuffered_read(remaining) }
        buffers << bytes
        remaining -= bytes.bytesize unless length.nil?
      end
    rescue EOFError
    end

    buffers.join('')
  end

  ##
  # @return [Symbol] a `Symbol` equivalent to the given `mode` for Ruby 2.7 and
  #   lower for use with `#wait`
  def wait_event_from_symbol(mode)
    case mode
    when :r, :read, :readable
      IO::READABLE
    when :w, :write, :writable
      IO::WRITABLE
    when :rw, :read_write, :readable_writable
      IO::READABLE || IO::WRITABLE
    else
      raise ArgumentError, "unsupported mode: #{mode}"
    end
  end
end
end

# vim: ts=2 sw=2 et
