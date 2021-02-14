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
      io.close
    end
  end

  def initialize
    @closed = false
  end

  def dup
    assert_open
    super
  end

  def advise(advice, offset, len)
    raise NotImplementedError
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

  def fcntl(*args)
    raise NotImplementedError
  end

  def fileno
    raise NotImplementedError
  end
  alias_method :to_i, :fileno

  def fsync
    raise NotImplementedError
  end
  alias_method :fdatasync, :fsync

  def ioctl(integer_cmd, arg)
    raise NotImplementedError
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
    raise NotImplementedError
  end

  def nread
    raise NotImplementedError
  end

  def read(length, buffer: nil)
    assert_readable
  end

  def readable?
    false
  end

  def ready?
    assert_open
    true
  end

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
  alias_method :isatty, :tty?

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

  def assert_open
    raise IOError, 'closed stream' if closed?
  end

  def assert_readable
    assert_open
    raise IOError, 'not opened for reading' unless readable?
  end

  def assert_writable
    assert_open
    raise IOError, 'not opened for writing' unless writable?
  end
end
end; end

# vim: ts=2 sw=2 et
