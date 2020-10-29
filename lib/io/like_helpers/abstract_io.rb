class IO; module LikeHelpers
class AbstractIO
  def initialize
    @closed = false
  end

  def advise(advice, offset, len)
    nil
  end

  def autoclose=(autoclose)
    autoclose
  end

  def autoclose?
    true
  end

  def close
    @closed = true
  end

  def closed?
    @closed
  end

  def close_on_exec=(close_on_exec)
    raise NotImplementedError
  end

  def close_on_exec?
    true
  end

  def fcntl(*args)
    raise NotImplementedError
  end

  def fileno
    nil
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
  end

  def nonblock?
    true
  end

  def pid
    nil
  end

  def nread
    0
  end

  def read(length, buffer: nil)
    raise IOError, 'closed stream' if closed?
    raise IOError, 'not opened for reading'
  end

  def readable?
    false
  end

  def ready?
    true
  end

  def seek(amount, whence)
    raise IOError, 'closed stream' if closed?
    raise Errno::ESPIPE
  end

  def seekable?
    return @seekable if defined? @seekable

    @seekable = begin
                  seek(0, IO::SEEK_CUR)
                  true
                rescue Errno::ESPIPE
                  false
                end
  end

  def stat
    raise NotImplementedError
  end

  def to_io
    raise NotImplementedError
  end

  def tty?
    false
  end
  alias_method :isatty, :tty?

  def wait(events, timeout = nil)
    true
  end

  def write(buffer, length: buffer.bytesize)
    raise IOError, 'closed stream' if closed?
    raise IOError, 'not opened for writing'
  end

  def writable?
    false
  end
end
end; end

# vim: ts=2 sw=2 et
