require 'io/like_helpers/delegated_io'
require 'io/like_helpers/io'

class IO; module LikeHelpers
class BufferedIO < DelegatedIO
  def initialize(delegate, autoclose: true, buffer_size: 8192)
    buffer_size = Integer(buffer_size)
    if buffer_size <= 0
      raise ArgumentError, 'buffer_size must be greater than 0'
    end

    super(delegate, autoclose: autoclose)

    @buffer_size = buffer_size
    @buffer = "\0".b * @buffer_size
    @start_idx = @end_idx = 0
    @mode = nil
  end

  def initialize_dup(other)
    assert_open
    super

    @buffer = @buffer.dup
  end

  attr_reader :buffer_size

  def close
    return nil if closed?

    if @mode == :write
      result = flush
      return result if Symbol === result
    end

    super
  end

  def fdatasync
    assert_open

    result = flush
    return result if Symbol === result
    super
  end

  def flush
    assert_open

    set_write_mode

    while @start_idx < @end_idx do
      remaining = @end_idx - @start_idx
      written = delegate.write(@buffer[@start_idx, remaining])
      return written if Symbol === written
      @start_idx += written
    end
    nil
  end

  def fsync
    assert_open

    result = flush
    return result if Symbol === result
    super
  end

  def nread
    assert_readable

    return 0 if read_buffer_empty?
    return @end_idx - @start_idx
  end

  # when unable to read in nonblocking mode, returns either :wait_readable or
  # :wait_writable
  # when given a buffer, returns the amount of content read
  # when not given a buffer, returns a new buffer containing the content read
  # the amount of content read may be less than requested
  # raises EOFError when reading at the end of file
  def read(length, buffer: nil)
    length = Integer(length)
    raise ArgumentError, 'length must be at least 0' if length < 0

    result = set_read_mode
    return result if Symbol === result

    # Reload the internal buffer when empty.
    if @start_idx >= @end_idx
      @start_idx = @end_idx = 0
      result = super(@buffer_size, buffer: @buffer)

      # Return non-integer results from the delegate.
      return result if Symbol === result

      @end_idx = result
    end

    available = @end_idx - @start_idx
    length = available if available < length
    content = @buffer[@start_idx, length]
    @start_idx += length
    return content if buffer.nil?

    buffer[0, length] = content
    return length
  end

  def read_buffer_empty?
    @mode != :read || @start_idx >= @end_idx
  end

  def seek(amount, whence = IO::SEEK_SET)
    case @mode
    when :write
      result = flush
      return result if Symbol === result
    when :read
      case whence
      when IO::SEEK_CUR, :CUR
        amount -= @end_idx - @start_idx
      end
    end
    @mode = nil

    result = super(amount, whence)
    # Clear the buffer only if the seek was successful.
    @start_idx = @end_idx = 0
    result
  end

  def unbuffered_read(length, buffer: nil)
    assert_readable
    delegate.read(length, buffer: buffer)
  end

  def unbuffered_seek(amount, whence = IO::SEEK_SET)
    assert_open
    delegate.seek(amount, whence)
  end

  def unbuffered_write(buffer, length: buffer.bytesize)
    assert_writable
    delegate.write(buffer, length: length)
  end

  def unread(buffer, length: buffer.bytesize)
    assert_readable

    length = Integer(length)
    raise ArgumentError, 'length must be at least 0' if length < 0

    result = set_read_mode
    return result if Symbol === result

    used = @end_idx - @start_idx
    if length > @buffer_size - used
      raise IOError, 'insufficient buffer space for unread'
    end

    if length > @start_idx
      # Shift the available buffer content to the end of the buffer
      @new_start_idx = @buffer_size - used
      @buffer[@new_start_idx, used] = @buffer[@start_idx, used]
      @start_idx = @new_start_idx
      @end_idx = @buffer_size
    end

    @start_idx -= length
    @buffer[@start_idx, length] = buffer[0, length]

    nil
  end

  def wait(events, timeout = nil)
    assert_open

    if events & (IO::READABLE | IO::PRIORITY) > 0 && ! read_buffer_empty?
      return true
    end

    super
  end

  def write(buffer, length: buffer.bytesize)
    assert_writable

    length = Integer(length)
    raise ArgumentError, 'length must be at least 0' if length < 0

    set_write_mode

    available = @buffer_size - @end_idx
    if available <= 0
      result = flush
      return result if Symbol === result

      @start_idx = @end_idx = 0
      available = @buffer_size
    end

    length = available if available < length
    @buffer[@end_idx, length] = buffer.b[0, length]
    @end_idx += length
    length
  end

  def write_buffer_empty?
    @mode != :write || @start_idx >= @end_idx
  end

  private

  def set_read_mode
    if @mode == :write
      result = flush
      return result if Symbol === result
    end
    @mode = :read
    nil
  end

  def set_write_mode
    if @mode == :read
      # Rewind delegate to buffered read position if possible.
      seek(0, IO::SEEK_CUR) rescue nil
      # Ensure the read buffer is cleared even if the stream is not seekable.
      @start_idx = @end_idx = 0
    end
    @mode = :write
    nil
  end
end
end; end

# vim: ts=2 sw=2 et
