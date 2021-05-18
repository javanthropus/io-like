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
    !!super
  end

  def seek(amount, whence = IO::SEEK_SET)
    delegate.sysseek(amount, whence)
  end

  def wait(events, timeout)
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
    !!delegate.wait(timeout, mode)
  end

  def write(buffer, length: buffer.bytesize)
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
