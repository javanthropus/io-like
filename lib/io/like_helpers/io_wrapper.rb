require 'fcntl'
require 'io/nonblock'
require 'io/wait'

require 'io/like_helpers/delegated_io'
require 'io/like_helpers/io'
require 'io/like_helpers/ruby_facts'

class IO; module LikeHelpers
class IOWrapper < DelegatedIO
  include RubyFacts

  def initialize(delegate)
    super(delegate, autoclose: true)

    flags = delegate.fcntl(Fcntl::F_GETFL) & Fcntl::O_ACCMODE
    @readable = flags == Fcntl::O_RDONLY || flags == Fcntl::O_RDWR
    @writable = flags == Fcntl::O_WRONLY || flags == Fcntl::O_RDWR
  end

  def read(length, buffer: nil)
    content = delegate.nonblock? ?
      read_nonblock(length) :
      delegate.sysread(length)

    return content if Symbol === content || buffer.nil?

    buffer[0, content.bytesize] = content
    return content.bytesize
  end

  def readable?
    @readable
  end

  def seek(amount, whence)
    delegate.sysseek(amount, whence)
  end

  def seekable?
    return @seekable if defined? @seekable

    @seekable = begin
                  delegate.seek(0, IO::SEEK_CUR)
                  true
                rescue Errno::ESPIPE
                  false
                end
  end

  def wait(events, timeout = nil)
    return super unless RBVER_LT_3_0

    mode = case events & (IO::READABLE | IO::WRITABLE)
           when IO::READABLE | IO::WRITABLE
             :read_write
           when IO::READABLE
             :read
           when IO::WRITABLE
             :write
           end
    delegate.wait(timeout, mode)
  end

  def write(buffer, length: buffer.bytesize)
    return delegate.syswrite(buffer[0, length]) unless delegate.nonblock?
    write_nonblock(buffer[0, length])
  end

  def writable?
    @writable
  end

  private

  def read_nonblock(length)
    result = delegate.read_nonblock(length, exception: false)
    raise EOFError if result.nil?
    result
  end

  def write_nonblock(buffer)
    result = delegate.write_nonblock(buffer, exception: false)
    raise EOFError if result.nil?
    result
  end
end
end; end

# vim: ts=2 sw=2 et
