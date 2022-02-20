require 'fcntl'
require 'io/nonblock'
require 'io/wait'

require 'io/like_helpers/delegated_io'
require 'io/like_helpers/io'
require 'io/like_helpers/ruby_facts'

class IO; module LikeHelpers

##
# This class adapts Ruby's IO implementation to the more primitive interface and
# behaviors expected by this library.
class IOWrapper < DelegatedIO
  include RubyFacts

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
    assert_readable
    content = nonblock? ?
      read_nonblock(length) :
      delegate.sysread(length)

    return content if Symbol === content || buffer.nil?

    buffer[0, content.bytesize] = content
    return content.bytesize
  end

  ##
  # Returns whether or not the stream is readable.
  #
  # @return [true] if the stream is readable
  # @return [false] if the stream is not readable
  def readable?
    return @readable if defined? @readable

    @readable =
      begin
        delegate.read(0)
        true
      rescue IOError
        false
      end
  end

  ##
  # Returns whether or not the stream has input available.
  #
  # @return [true] if input is available
  # @return [false] if input is not available
  def ready?
    # This is a hack to work around the fact that IO#ready? returns an object
    # instance instead of true, contrary to documentation.
    !!super
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
  # @param amount [Integer] the amount to move the position in bytes
  # @param whence [Integer, Symbol] the position alias from which to consider
  #   _amount_
  #
  # @return [Integer] the new stream position
  #
  # @raise [IOError] if the stream is closed
  # @raise [Errno::ESPIPE] if the stream is not seekable
  def seek(amount, whence = IO::SEEK_SET)
    assert_open
    delegate.sysseek(amount, whence)
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
    # The !! is a hack to work around the fact that IO#wait returns an object
    # instance instead of true, contrary to documentation.
    return !!super unless RBVER_LT_3_0

    # The rest of this implementation is for backward compatibility with the
    # IO#wait implamentation on Ruby versions prior to 3.0.
    #
    # TODO:
    # Remove this when Ruby 2.7 and below are no longer supported by this
    # library.
    assert_open
    mode =
      case events & (IO::READABLE | IO::WRITABLE)
      when IO::READABLE | IO::WRITABLE
        :read_write
      when IO::READABLE
        :read
      when IO::WRITABLE
        :write
      else
        return false
      end
    # The !! is a hack to work around the fact that IO#wait returns an object
    # instance instead of true, contrary to documentation.
    !!delegate.wait(timeout, mode)
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
    return delegate.syswrite(buffer[0, length]) unless nonblock?
    write_nonblock(buffer[0, length])
  end

  ##
  # Returns whether or not the stream is writable.
  #
  # @return [true] if the stream is writable
  # @return [false] if the stream is not writable
  def writable?
    return @writable if defined? @writable

    @writable =
      begin
        delegate.write
        true
      rescue IOError
        false
      end
  end

  private

  ##
  # Reads bytes from the stream without blocking.
  #
  # Note that a partial read will occur if reading starts at the end of the
  # stream or if reading more bytes would block.
  #
  # @param length [Integer] the number of bytes to read
  #
  # @return [String] a buffer containing the bytes read
  # @return [:wait_readable, :wait_writable] if the stream is non-blocking and
  #   the operation would block
  #
  # @raise [EOFError] when reading at the end of the stream
  # @raise [IOError] if the stream is not readable
  def read_nonblock(length)
    result = delegate.read_nonblock(length, exception: false)
    raise EOFError if result.nil?
    result
  end

  ##
  # Writes bytes to the stream without blocking.
  #
  # Note that a partial write will occur if writing more bytes would block.
  #
  # @param buffer [String] the bytes to write (encoding assumed to be binary)
  #
  # @return [Integer] the number of bytes written
  # @return [:wait_readable, :wait_writable] if the stream is non-blocking and
  #   the operation would block
  #
  # @raise [IOError] if the stream is not writable
  def write_nonblock(buffer)
    delegate.write_nonblock(buffer, exception: false)
  end
end
end; end

# vim: ts=2 sw=2 et
