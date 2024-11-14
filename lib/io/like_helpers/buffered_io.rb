# frozen_string_literal: true

require 'io/like_helpers/delegated_io'
require 'io/like_helpers/io'

class IO; module LikeHelpers

##
# This class implements a stream that buffers data read from or written to a
# delegate.
class BufferedIO < DelegatedIO
  ##
  # Creates a new intance of this class.
  #
  # @param delegate [LikeHelpers::AbstractIO] a readable and/or writable stream
  # @param autoclose [Boolean] when `true` close the delegate when this stream
  #   is closed
  # @param buffer_size [Integer] the size of the internal buffer in bytes
  def initialize(delegate, autoclose: true, buffer_size: 8192)
    buffer_size = Integer(buffer_size)
    if buffer_size <= 0
      raise ArgumentError, 'buffer_size must be greater than 0'
    end

    super(delegate, autoclose: autoclose)

    @buffer_size = buffer_size
    @buffer = String.new("\0".b * @buffer_size)
    @start_idx = @end_idx = @unread_offset = 0
    @mode = nil
  end

  ##
  # The size of the internal buffer in bytes.
  attr_reader :buffer_size

  ##
  # Closes this stream, flushing data from the write buffer first if necessary.
  #
  # The delegate is closed if autoclose is enabled for the stream.
  #
  # @return [nil] on success
  # @return [:wait_readable, :wait_writable] if the stream is non-blocking and
  #   the operation would block
  def close
    return nil if closed?

    if @mode == :write
      result = flush
      return result if Symbol === result
    end

    super
  end

  ##
  # Flushes any data in the write buffer and then forwards the call to the
  # delegate.
  #
  # @return [0, nil] on success
  # @return [:wait_readable, :wait_writable] if the stream is non-blocking and
  #   the operation would block
  def fdatasync
    assert_open

    result = flush
    return result if Symbol === result
    super
  end

  ##
  # Flushes any data in the write buffer to the delegate.
  #
  # @return [nil] on success
  # @return [:wait_readable, :wait_writable] if the stream is non-blocking and
  #   the operation would block
  #
  # @raise [IOError] if the stream is closed
  def flush
    assert_open

    set_write_mode

    while @start_idx < @end_idx do
      remaining = @end_idx - @start_idx
      result = delegate.write(@buffer[@start_idx, remaining])
      return result if Symbol === result
      @start_idx += result
    end
    nil
  end

  ##
  # Flushes any data in the write buffer and then forwards the call to the
  # delegate.
  #
  # @return [0, nil] on success
  # @return [:wait_readable, :wait_writable] if the stream is non-blocking and
  #   the operation would block
  #
  # @raise [IOError] if the stream is closed
  def fsync
    result = flush
    return result if Symbol === result
    super
  end

  ##
  # @return [Integer] the number of bytes available to read from the internal
  #   buffer
  #
  # @raise [IOError] if the stream is not readable
  def nread
    assert_readable

    return 0 if read_buffer_empty?
    return @end_idx - @start_idx
  end

  ##
  # Reads up to `length` bytes from the read buffer but does not advance the
  # stream position.
  #
  # @param length [Integer, nil] the number of bytes to read or `nil` for all
  #   bytes
  #
  # @return [String] a buffer containing the bytes read
  #
  # @raise [IOError] if the stream is not readable
  def peek(length = nil)
    if length.nil?
      length = nread
    else
      length = Integer(length)
      raise ArgumentError, 'length must be at least 0' if length < 0
    end

    assert_readable

    return ''.b unless @mode == :read

    available = @end_idx - @start_idx
    length = available if available < length
    return @buffer[@start_idx, length]
  end

  ##
  # Reads at most `length` bytes from the stream starting at `offset` without
  # modifying the read position in the stream.
  #
  # Note that a partial read will occur if the stream is in non-blocking mode
  # and reading more bytes would block.
  #
  # @note This method is not thread safe.  Override it and add a mutex if thread
  #   safety is desired.
  #
  # @param length [Integer] the maximum number of bytes to read
  # @param offset [Integer] the offset from the beginning of the stream at which
  #   to begin reading
  # @param buffer [String] if provided, a buffer into which the bytes should be
  #   placed
  # @param buffer_offset [Integer] the index at which to insert bytes into
  #   `buffer`
  #
  # @return [Integer] the number of bytes read if `buffer` is not `nil`
  # @return [String] a new String containing the bytes read if `buffer` is `nil`
  #   or `buffer` if provided
  # @return [:wait_readable, :wait_writable] if the stream is non-blocking and
  #   the operation would block
  #
  # @raise [EOFError] when reading at the end of the stream
  # @raise [IOError] if the stream is not readable
  def pread(length, offset, buffer: nil, buffer_offset: 0)
    offset = Integer(offset)
    raise ArgumentError, 'offset must be at least 0' if offset < 0
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

    result = set_read_mode
    return result if Symbol === result

    super
  end

  ##
  # Writes at most `length` bytes to the stream starting at `offset` without
  # modifying the write position in the stream.
  #
  # Note that a partial write will occur if the stream is in non-blocking mode
  # and writing more bytes would block.
  #
  # @note This method is not thread safe.  Override it and add a mutex if thread
  #   safety is desired.
  #
  # @param buffer [String] the bytes to write (encoding assumed to be binary)
  # @param offset [Integer] the offset from the beginning of the stream at which
  #   to begin writing
  # @param length [Integer] the number of bytes to write from `buffer`
  #
  # @return [Integer] the number of bytes written
  # @return [:wait_readable, :wait_writable] if the stream is non-blocking and
  #   the operation would block
  #
  # @raise [IOError] if the stream is not writable
  def pwrite(buffer, offset, length: buffer.bytesize)
    offset = Integer(offset)
    raise ArgumentError, 'offset must be at least 0' if offset < 0
    length = Integer(length)
    raise ArgumentError, 'length must be at least 0' if length < 0

    assert_writable

    set_write_mode

    super
  end

  ##
  # Reads bytes from the stream.
  #
  # Note that a partial read will occur if the stream is in non-blocking mode
  # and reading more bytes would block.
  #
  # @param length [Integer] the number of bytes to read
  # @param buffer [String] the buffer into which bytes will be read (encoding
  #   assumed to be binary)
  # @param buffer_offset [Integer] the index at which to insert bytes into
  #   `buffer`
  #
  # @return [Integer] the number of bytes read if `buffer` is not `nil`
  # @return [String] a buffer containing the bytes read if `buffer` is `nil`
  # @return [:wait_readable, :wait_writable] if the stream is non-blocking and
  #   the operation would block
  #
  # @raise [EOFError] when reading at the end of the stream
  # @raise [IOError] if the stream is not readable
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

    # Reload the internal buffer when empty.
    if read_buffer_empty?
      result = refill
      return result if Symbol === result
    end

    available = @end_idx - @start_idx
    length = available if available < length
    content = @buffer[@start_idx, length]
    @start_idx += length
    @unread_offset += [@unread_offset, length].min
    return content if buffer.nil?

    buffer[buffer_offset, length] = content
    return length
  end

  ##
  # Returns `true` if the read buffer is empty and `false` otherwise.
  #
  # @return [Boolean]
  def read_buffer_empty?
    @mode != :read || @start_idx >= @end_idx
  end

  ##
  # Refills the read buffer.
  #
  # @return [Integer] the number of bytes added to the read buffer
  # @return [:wait_readable, :wait_writable] if the stream is non-blocking and
  #   the operation would block
  #
  # @raise [EOFError] when reading at the end of the stream
  # @raise [IOError] if the stream is not readable
  def refill
    assert_readable

    result = set_read_mode
    return result if Symbol === result

    remaining = @end_idx - @start_idx
    available = buffer_size - remaining
    if available == 0
      # The read buffer is already full.
      return 0
    elsif available < buffer_size
      if @start_idx > 0
        # Shift the remaining buffer content to the beginning of the buffer.
        @buffer[0, remaining] = @buffer[@start_idx, remaining]
        @start_idx = 0
        @end_idx = remaining
      end
    else
      # The read buffer is empty, so prepare to fill it at the beginning.
      @start_idx = @end_idx = @unread_offset = 0
    end

    result =
      delegate.read(available, buffer: @buffer, buffer_offset: @end_idx)

    # Return non-integer results from the delegate.
    return result if Symbol === result

    @end_idx += result

    result
  end

  ##
  # Sets the current stream position to `amount` based on the setting of
  # `whence`.
  #
  # | `whence` | `amount` Interpretation |
  # | -------- | ----------------------- |
  # | `:CUR` or `IO::SEEK_CUR` | `amount` added to current stream position |
  # | `:END` or `IO::SEEK_END` | `amount` added to end of stream position (`amount` will usually be negative here) |
  # | `:SET` or `IO::SEEK_SET` | `amount` used as absolute position |
  #
  # @param amount [Integer] the amount to move the position in bytes
  # @param whence [Integer, Symbol] the position alias from which to consider
  #   `amount`
  #
  # @return [Integer] the new stream position
  #
  # @raise [IOError] if the stream is closed
  # @raise [Errno::ESPIPE] if the stream is not seekable
  def seek(amount, whence = IO::SEEK_SET)
    case @mode
    when :write
      result = flush
      return result if Symbol === result
    when :read
      case whence
      when IO::SEEK_CUR, :CUR
        amount -= @end_idx - @start_idx - @unread_offset
      end
    end
    @mode = nil

    result = super(amount, whence)
    # Clear the buffer only if the seek was successful.
    @start_idx = @end_idx = @unread_offset = 0
    result
  end

  ##
  # Advances forward in the read buffer up to `length` bytes.
  #
  # @param length [Integer, nil] the number of bytes to skip or `nil` for all
  #   bytes
  #
  # @return [Integer] the number of bytes actually skipped
  #
  # @raise [IOError] if the stream is not readable
  def skip(length = nil)
    if length.nil?
      length = nread
    else
      length = Integer(length)
      raise ArgumentError, 'length must be at least 0' if length < 0
    end

    assert_readable

    return 0 unless @mode == :read

    remaining = @end_idx - @start_idx
    length = remaining if length > remaining
    @start_idx += length
    @unread_offset += [@unread_offset, length].min

    length
  end

  ##
  # Places bytes at the beginning of the read buffer.
  #
  # @param buffer [String] the bytes to insert into the read buffer
  # @param length [Integer] the number of bytes from the beginning of `buffer`
  #   to insert into the read buffer
  #
  # @return [nil]
  #
  # @raise [IOError] if the remaining space in the internal buffer is
  #   insufficient to contain the given data
  # @raise [IOError] if the stream is not readable
  def unread(buffer, length: buffer.bytesize)
    length = Integer(length)
    raise ArgumentError, 'length must be at least 0' if length < 0

    assert_readable

    result = set_read_mode
    return result if Symbol === result

    used = @end_idx - @start_idx
    if length > @buffer_size - used
      raise IOError, 'insufficient buffer space for unread'
    end

    if length > @start_idx
      # Shift the available buffer content to the end of the buffer
      new_start_idx = @buffer_size - used
      @buffer[new_start_idx, used] = @buffer[@start_idx, used]
      @start_idx = new_start_idx
      @end_idx = @buffer_size
    end

    @start_idx -= length
    @unread_offset += length
    @buffer[@start_idx, length] = buffer[0, length]

    nil
  end

  ##
  # Waits until the stream becomes ready for at least 1 of the specified events.
  #
  # @param events [Integer] a bit mask of `IO::READABLE`, `IO::WRITABLE`, or
  #   `IO::PRIORITY`
  # @param timeout [Numeric, nil] the timeout in seconds or no timeout if `nil`
  #
  # @return [true] if the stream becomes ready for at least one of the given
  #   events
  # @return [false] if the IO does not become ready before the timeout
  def wait(events, timeout = nil)
    assert_open

    if events & (IO::READABLE | IO::PRIORITY) > 0 && ! read_buffer_empty?
      return true
    end

    super
  end

  ##
  # Writes bytes to the stream.
  #
  # Note that a partial write will occur if the stream is in non-blocking mode
  # and writing more bytes would block.
  #
  # @param buffer [String] the bytes to write (encoding assumed to be binary)
  # @param length [Integer] the number of bytes to write from `buffer`
  #
  # @return [Integer] the number of bytes written
  # @return [:wait_readable, :wait_writable] if the stream is non-blocking and
  #   the operation would block
  #
  # @raise [IOError] if the stream is not writable
  def write(buffer, length: buffer.bytesize)
    length = Integer(length)
    raise ArgumentError, 'length must be at least 0' if length < 0

    assert_writable

    set_write_mode

    available = @buffer_size - @end_idx
    if available <= 0
      result = flush
      return result if Symbol === result

      @start_idx = @end_idx = @unread_offset = 0
      available = @buffer_size
    end

    length = available if available < length
    @buffer[@end_idx, length] = buffer.b[0, length]
    @end_idx += length
    length
  end

  ##
  # Returns `true` if the write buffer it empty and `false` otherwise.
  #
  # @return [Boolean]
  def write_buffer_empty?
    @mode != :write || @start_idx >= @end_idx
  end

  private

  ##
  # Creates an instance of this class that copies state from `other`.
  #
  # @param other [BufferedIO] the instance to copy
  #
  # @return [nil]
  #
  # @raise [IOError] if `other` is closed
  def initialize_copy(other)
    super

    @buffer = @buffer.dup

    nil
  end

  ##
  # Switches the stream into read mode if it was previously in write mode.
  #
  # This triggers a flush operation if needed.
  #
  # @return [nil] if read mode is enabled
  # @return [:wait_readable, :wait_writable] if a flush is needed and would
  #   block
  def set_read_mode
    if @mode == :write
      result = flush
      return result if Symbol === result
    end
    @mode = :read
    nil
  end

  ##
  # Switches the stream into write mode if it was previously in read mode.
  #
  # @return [nil]
  def set_write_mode
    if @mode == :read
      # Rewind delegate to buffered read position if possible.
      seek(0, IO::SEEK_CUR) rescue nil
      # Ensure the read buffer is cleared even if the stream is not seekable.
      @start_idx = @end_idx = @unread_offset = 0
    end
    @mode = :write
    nil
  end
end
end; end

# vim: ts=2 sw=2 et
