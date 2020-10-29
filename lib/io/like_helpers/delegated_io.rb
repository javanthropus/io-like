class IO; module LikeHelpers
class DelegatedIO
  def initialize(delegate, autoclose: true)
    raise ArgumentError, 'delegate cannot be nil' if delegate.nil?

    @delegate = delegate
    @autoclose = autoclose

    @closed = false
  end

  def initialize_dup(other)
    super

    @delegate = @delegate.dup
  end

  attr_reader :delegate

  def advise(advice, offset = 0, len = 0)
    delegate.advise(advice, offset, len)
  end

  ##
  # Sets whether or not to close the delegate(s) when {#close} is called.
  #
  # @param autoclose [Boolean] delegate(s) will be closed when `true`
  def autoclose=(autoclose)
    @autoclose = autoclose ? true : false
    autoclose
  end

  ##
  # @return [true] if delegate(s) would be closed when {#close} is called
  # @return [false] if delegate(s) would **not** be closed when {#close} is called
  def autoclose?
    @autoclose
  end

  def close
    return if @closed

    if @autoclose
      result = delegate.close
      return result if Symbol === result
    end
    @closed = true

    nil
  end

  def closed?
    @closed
  end

  def close_on_exec=(close_on_exec)
    delegate.close_on_exec = close_on_exec
    nil
  end

  def close_on_exec?
    delegate.close_on_exec?
  end

  def fcntl(*args)
    delegate.fcntl(*args)
  end

  def fdatasync
    delegate.fdatasync
  end

  def fileno
    delegate.fileno
  end
  alias_method :to_i, :fileno

  def fsync
    delegate.fsync
  end

  def ioctl(integer_cmd, arg)
    delegate.ioctl(integer_cmd, arg)
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
    orig_nonblock = nonblock?
    self.nonblock = nonblock
    yield(self)
  ensure
    self.nonblock = orig_nonblock
  end

  def nonblock=(nonblock)
    delegate.nonblock = nonblock
    nonblock
  end

  def nonblock?
    delegate.nonblock?
  end

  def nread
    delegate.nread
  end

  def path
    delegate.path
  end

  def pid
    delegate.pid
  end

  def read(length, buffer: nil)
    delegate.read(length, buffer: buffer)
  end

  def readable?
    delegate.readable?
  end

  def ready?
    delegate.ready?
  end

  def seek(amount, whence = IO::SEEK_SET)
    delegate.seek(amount, whence)
  end

  def seekable?
    delegate.seekable?
  end

  def stat
    delegate.stat
  end

  def to_io
    delegate.to_io
  end

  def tty?
    delegate.tty?
  end
  alias_method :isatty, :tty?

  def wait(events, timeout)
    delegate.wait(events, timeout)
  end

  def write(buffer, length: buffer.bytesize)
    delegate.write(buffer, length: length)
  end

  def writable?
    delegate.writable?
  end
end
end; end

# vim: ts=2 sw=2 et
