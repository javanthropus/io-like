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
    @start_idx = @end_idx = 0
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

  ##
  # Flushes any data in the write buffer and then forwards the call to the
  # delegate.
  #
  # @return [0, nil] on success
  # @return [:wait_readable, :wait_writable] if the stream is non-blocking and
  #   the operation would block
  def fsync
    assert_open

    result = flush
    return result if Symbol === result
    super
  end

  ##
  # @return [Integer] the number of bytes availble to read from the internal
  #   buffer
  #
  # @raise [IOError] if the stream is not readable
  def nread
    assert_readable

    result = set_read_mode
    return result if Symbol === result

    return delegate.nread if read_buffer_empty?
    return @end_idx - @start_idx
  end

  ##
  # Reads bytes from the stream.
  #
  # Note that a partial read will occur if reading starts at the end of the
  # stream or if reading more bytes would block while the stream is in
  # non-blocking mode.
  #
  # @param length [Integer] the number of bytes to read
  # @param buffer [String] the buffer into which bytes will be read (encoding
  #   assumed to be binary)
  #
  # @return [Integer] the number of bytes read if `buffer` is not `nil`
  # @return [String] a buffer containing the bytes read if `buffer` is `nil`
  # @return [:wait_readable, :wait_writable] if the stream is non-blocking and
  #   the operation would block
  #
  # @raise [EOFError] when reading at the end of the stream
  # @raise [IOError] if the stream is not readable
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

  ##
  # Returns `true` if the read buffer is empty and `false` otherwise.
  #
  # @return [Boolean]
  def read_buffer_empty?
    @mode != :read || @start_idx >= @end_idx
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
        amount -= @end_idx - @start_idx
      end
    end
    @mode = nil

    result = super(amount, whence)
    # Clear the buffer only if the seek was successful.
    @start_idx = @end_idx = 0
    result
  end

  ##
  # Reads bytes from the stream, bypassing the internal buffer.
  #
  # Note that this method does not warn or error if there are bytes in the
  # internal buffer.
  #
  # @param length [Integer] the number of bytes to read
  # @param buffer [String] the buffer into which bytes will be read (encoding
  #   assumed to be binary)
  #
  # @return [Integer] the number of bytes read if `buffer` is not `nil`
  # @return [String] a buffer containing the bytes read if `buffer` is `nil`
  # @return [:wait_readable, :wait_writable] if the stream is non-blocking and
  #   the operation would block
  #
  # @raise [EOFError] when reading at the end of the stream
  # @raise [IOError] if the stream is not readable
  def unbuffered_read(length, buffer: nil)
    assert_readable
    delegate.read(length, buffer: buffer)
  end

  ##
  # Sets the current stream position to _amount_ based on the setting of
  # _whence_, ignoring the internal buffer state.
  #
  # Note that this method does not warn or error if there are bytes in the
  # internal buffer.
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
  # @return [Integer] the new stream position
  #
  # @raise [IOError] if the stream is closed
  # @raise [Errno::ESPIPE] if the stream is not seekable
  def unbuffered_seek(amount, whence = IO::SEEK_SET)
    assert_open
    delegate.seek(amount, whence)
  end

  ##
  # Writes bytes to the stream, bypassing the internal buffer.
  #
  # Note that this method does not warn or error if there are bytes in the
  # internal buffer.
  #
  # @param buffer [String] the bytes to write (encoding assumed to be binary)
  # @param length [Integer] the number of bytes to write from `buffer`
  #
  # @return [Integer] the number of bytes written
  # @return [:wait_readable, :wait_writable] if the stream is non-blocking and
  #   the operation would block
  #
  # @raise [IOError] if the stream is not writable
  def unbuffered_write(buffer, length: buffer.bytesize)
    assert_writable
    delegate.write(buffer, length: length)
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
      @start_idx = @end_idx = 0
    end
    @mode = :write
    nil
  end
end
end; end

# vim: ts=2 sw=2 et
