require 'fcntl'
require 'io/nonblock'
require 'io/wait'

require 'io/like_helpers/delegated_io'
require 'io/like_helpers/io'
require 'io/like_helpers/ruby_facts'

class IO; module LikeHelpers
class IOWrapper < DelegatedIO
  include RubyFacts

  def read(length, buffer: nil)
    assert_readable
    content = delegate.nonblock? ?
      read_nonblock(length) :
      delegate.sysread(length)

    return content if Symbol === content || buffer.nil?

    buffer[0, content.bytesize] = content
    return content.bytesize
  end

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

  def ready?
    # This is a hack to work around the fact that IO#ready? returns an object
    # instance instead of true, contrary to documentation.
    !!super
  end

  ##
  # Sets the current, unbuffered stream position to _offset_ based on the
  # setting of _whence_.
  #
  # | _whence_ | _offset_ Interpretation |
  # | -------- | ----------------------- |
  # | `:CUR` or `IO::SEEK_CUR` | _offset_ added to current stream position |
  # | `:END` or `IO::SEEK_END` | _offset_ added to end of stream position (_offset_ will usually be negative here) |
  # | `:SET` or `IO::SEEK_SET` | _offset_ used as absolute position |
  #
  # @param offset [Integer] the amount to move the position in bytes
  # @param whence [Integer, Symbol] the position alias from which to consider
  #   _offset_
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

    mode = case events & (IO::READABLE | IO::WRITABLE)
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

  def write(buffer, length: buffer.bytesize)
    assert_writable
    return delegate.syswrite(buffer[0, length]) unless delegate.nonblock?
    write_nonblock(buffer[0, length])
  end

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

  def read_nonblock(length)
    result = delegate.read_nonblock(length, exception: false)
    raise EOFError if result.nil?
    result
  end

  def write_nonblock(buffer)
    delegate.write_nonblock(buffer, exception: false)
  end
end
end; end

# vim: ts=2 sw=2 et
