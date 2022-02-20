class IO; module LikeHelpers
class AbstractIO
  ##
  # @overload open(*args, **kwargs)
  #   Equivalent to {#initialize}.
  #
  #   @return a new instances of this class
  #
  # @overload open(*args, **kwargs)
  #   Yields the new instance of this class to the block, ensures the instance
  #   is closed once the block completes, and returns the result of the block.
  #
  #   @yieldparam stream an instance of this class
  #
  #   @return [block result]
  #
  # @param args a list of arguments passed to the initializer of this class
  # @param kwargs a list of keyword arguments passed to the initializer of this
  #   class
  def self.open(*args, **kwargs)
    io = new(*args, **kwargs)
    return io unless block_given?

    begin
      yield(io)
    ensure
      while Symbol === io.close do
        warn 'warning: waiting for nonblocking close to complete at the end of the open method'
        # A wait timeout is used in order to allow a retry in case the stream
        # was closed in another thread while waiting.
        io.wait(IO::READABLE | IO::WRITABLE, 1)
      end
    end
  end

  ##
  # Creates a new instance of this class.
  #
  # @param kwargs [Hash] only provided for compatibility with .open on Ruby 2.6
  #
  # TODO:
  # Remove explicit _kwargs_ parameter when Ruby 2.6 support is dropped.
  def initialize(**kwargs)
    @closed = false
  end

  def advise(advice, offset = 0, len = 0)
    nil
  end

  def close
    @closed = true
    nil
  end

  def closed?
    @closed
  end

  def close_on_exec=(close_on_exec)
    raise NotImplementedError
  end

  def close_on_exec?
    raise NotImplementedError
  end

  def fcntl(integer_cmd, arg)
    raise NotImplementedError
  end

  def fileno
    raise NotImplementedError
  end

  def fsync
    raise NotImplementedError
  end
  alias_method :fdatasync, :fsync

  def ioctl(integer_cmd, arg)
    raise NotImplementedError
  end

  ##
  # Yields `self` to the given block after setting the blocking mode as dictated
  # by `nonblock`.
  #
  # Ensures that the original blocking mode is reinstated after yielding.
  #
  # @param nonblock [Boolean] sets the stream to non-blocking mode if `true` and
  #   blocking mode otherwise
  #
  # @yieldparam self [Like] this stream
  #
  # @return [self]
  def nonblock(nonblock = true)
    assert_open
    begin
      orig_nonblock = nonblock?
      self.nonblock = nonblock
      yield(self)
    ensure
      self.nonblock = orig_nonblock
    end
  end

  def nonblock=(nonblock)
    raise NotImplementedError
  end

  def nonblock?
    raise NotImplementedError
  end

  def path
    raise NotImplementedError
  end

  def pid
    assert_open
    nil
  end

  def read(length, buffer: nil)
    assert_readable
  end

  def readable?
    false
  end

  def ready?
    assert_open
    false
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
  def seek(amount, whence)
    assert_open
    raise Errno::ESPIPE
  end

  def stat
    raise NotImplementedError
  end

  def to_io
    raise NotImplementedError
  end

  def tty?
    assert_open
    false
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
    raise NotImplementedError
  end

  def write(buffer, length: buffer.bytesize)
    assert_writable
  end

  def writable?
    false
  end

  private

  ##
  # Raises an exception if the stream is closed.
  #
  # @return [nil]
  #
  # @raise IOError if the stream is closed
  def assert_open
    raise IOError, 'closed stream' if closed?
  end

  ##
  # Raises an exception if the stream is closed or not open for reading.
  #
  # @return [nil]
  #
  # @raise IOError if the stream is closed or not open for reading
  def assert_readable
    assert_open
    raise IOError, 'not opened for reading' unless readable?
  end

  def assert_writable
    assert_open
    raise IOError, 'not opened for writing' unless writable?
  end

  def initialize_copy(other)
    assert_open

    super

    nil
  end
end
end; end

# vim: ts=2 sw=2 et
