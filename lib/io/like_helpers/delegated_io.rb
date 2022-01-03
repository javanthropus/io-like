require 'io/like_helpers/abstract_io'

class IO; module LikeHelpers
class DelegatedIO < AbstractIO
  def initialize(delegate, autoclose: true)
    raise ArgumentError, 'delegate cannot be nil' if delegate.nil?
    super()

    @delegate = delegate
    @autoclose = autoclose
  end

  def initialize_dup(other)
    super

    @autoclose = true
    @delegate = @delegate.dup
  end

  def advise(advice, offset = 0, len = 0)
    assert_open
    delegate.advise(advice, offset, len)
  end

  ##
  # Sets whether or not to close the delegate(s) when {#close} is called.
  #
  # @param autoclose [Boolean] delegate(s) will be closed when `true`
  def autoclose=(autoclose)
    assert_open
    @autoclose = autoclose ? true : false
    autoclose
  end

  ##
  # @return [true] if delegate(s) would be closed when {#close} is called
  # @return [false] if delegate(s) would **not** be closed when {#close} is called
  def autoclose?
    assert_open
    @autoclose
  end

  def close
    return nil if closed?

    if @autoclose
      result = delegate.close
      return result if Symbol === result
    end
    super

    nil
  end

  def closed?
    @closed
  end

  def close_on_exec=(close_on_exec)
    assert_open
    delegate.close_on_exec = close_on_exec
    nil
  end

  def close_on_exec?
    assert_open
    delegate.close_on_exec?
  end

  def fcntl(*args)
    assert_open
    delegate.fcntl(*args)
  end

  def fdatasync
    assert_open
    delegate.fdatasync
  end

  def fileno
    assert_open
    delegate.fileno
  end
  alias_method :to_i, :fileno

  def fsync
    assert_open
    delegate.fsync
  end

  ##
  # @return [String] a string representation of this object
  def inspect
    "<#{self.class}:#{delegate.inspect}>"
  end

  def ioctl(integer_cmd, arg)
    assert_open
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
    begin
      yield(self)
    ensure
      self.nonblock = orig_nonblock
    end
  end

  def nonblock=(nonblock)
    assert_open
    delegate.nonblock = nonblock
    nonblock
  end

  def nonblock?
    assert_open
    delegate.nonblock?
  end

  ##
  # @return [Integer] the number of bytes that can be read without blocking or
  #   `0` if unknown
  #
  # @raise [IOError] if the stream is not open for reading
  def nread
    assert_readable
    delegate.nread
  end

  def path
    assert_open
    delegate.path
  end

  def pid
    assert_open
    delegate.pid
  end

  def read(length, buffer: nil)
    assert_readable
    delegate.read(length, buffer: buffer)
  end

  def readable?
    return false if closed?
    delegate.readable?
  end

  def ready?
    assert_open
    delegate.ready?
  end

  def seek(amount, whence = IO::SEEK_SET)
    assert_open
    delegate.seek(amount, whence)
  end

  def stat
    assert_open
    delegate.stat
  end

  def to_io
    assert_open
    delegate.to_io
  end

  def tty?
    assert_open
    delegate.tty?
  end
  alias_method :isatty, :tty?

  def wait(events, timeout = nil)
    assert_open
    delegate.wait(events, timeout)
  end

  def write(buffer, length: buffer.bytesize)
    assert_writable
    delegate.write(buffer, length: length)
  end

  def writable?
    return false if closed?
    delegate.writable?
  end

  private

  def delegate
    raise IOError, 'uninitialized stream' if @delegate.nil?
    @delegate
  end
end
end; end

# vim: ts=2 sw=2 et
