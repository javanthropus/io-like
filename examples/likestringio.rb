require 'io/like'
require 'io/like_helpers/abstract_io'

class LikeStringIO < IO::Like
  class StringWrapper < IO::LikeHelpers::AbstractIO
    def initialize(string, append: false, truncate: false)
      super()

      @string = string
      @string.clear if truncate
      @append = append
      @pos = 0

      @delegate = self
    end

    attr_reader :string

    def string=(string)
      @string = string
    end

    def read(length, buffer: nil)
      raise EOFError, 'end of file reached' if @pos >= @string.bytesize

      content = @string.b[@pos, length]
      return content if buffer.nil?

      buffer[0, content.bytesize] = content
      return content.bytesize
    end
    alias_method :unbuffered_read, :read

    def read_buffer_empty?
      true
    end

    def seek(amount, whence)
      case whence
      when IO::SEEK_SET, :SET
        new_pos = amount
      when IO::SEEK_CUR, :CUR
        new_pos = @pos + amount
      when IO::SEEK_END, :END
        new_pos = @string.bytesize + amount
      end

      raise Errno::EINVAL, 'Invalid argument' if new_pos < 0

      @pos = new_pos
    end
    alias_method :unbuffered_seek, :seek

    def truncate(length)
      @string.slice!(length..-1)
      0
    end

    def unread(buffer, length: buffer.bytesize)
      length = Integer(length)
      raise ArgumentError 'length must be at least 0' if length < 0

      return nil if length == 0

      amount = length
      amount = @pos if amount > @pos
      start = @pos - amount
      @string[start, amount] = buffer[-amount, amount]
      remaining = length - amount
      @string.insert(0, buffer[0, remaining]) if remaining > 0
      @pos -= amount

      nil
    end

    def write(buffer, length: buffer.bytesize)
      @pos = @string.bytesize if append

      # Pad any space between the end of the wrapped string and the current
      # position with null characters.
      if @pos > @string.bytesize then
        @string << "\0" * (@pos - @string.bytesize)
      end

      @string.force_encoding('binary')
      buffer.force_encoding('binary')
      @string[@pos, length] = buffer[0, length]
      @string.force_encoding(external_encoding)
      buffer.force_encoding(external_encoding)
      @pos += length

      length
    end
    alias_method :unbuffered_write, :write

    def write_buffer_empty?
      true
    end
  end

  def initialize(string = '', mode = 'r+')
    super(StringWrapper.new(string, mode))
  end

  def reopen()
    unless args.size == 1 || args.size == 2
      raise ArgumentError,
        "wrong number of arguments (given #{args.size}, expected 1..2)"
    end
  end

  def set_encoding(ext_enc, int_enc = nil, **kwargs)
    @external_encoding = Encoding.find(ext_enc)
    @internal_encoding = nil
    string.force_encoding(@external_encoding)

    self
  end

  def size
    @delegate.string.bytesize
  end

  def string
    @delegate.string
  end

  def string=(string)
    @delegate.string = string
  end

  def truncate(length)
    raise IOError, 'not opened for writing' unless @writable
    @delegate.truncate(length)
  end
end

# vim: ts=2 sw=2 et
