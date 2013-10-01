# encoding: UTF-8

$: << File.expand_path('../../../lib', __FILE__)

require 'io/like'
require 'fcntl'

class IOWrapper < IO::Like
  def initialize(io, *args)
    @io = io
    @readable = false
    @writable = false
    @duplexed = false
    @nonblock = false

    args.pop if args.last.kind_of?(Hash)
    set_mode(args.first)

    if io.respond_to?(:external_encoding)
      @external_encoding = io.external_encoding
    end
    # One sysread spec needs fill_size 0, but then we wouldn't be testing our
    # buffering
    #self.fill_size = 0 if readable?
  end

  def flush()
    super
    @io.flush
  end

  def fsync()
    flush()
    @io.fsync
  end

  def path
    @io.path
  end

  def dup
    duped = super
    duped.reopen(@io.dup)
    duped
  end

  def nonblock=(nb)
    @nonblock = nb
  end

  def reopen(io)
    @io = io
  end

  def readable?; @readable; end
  def writable?; @writable; end
  def duplexed?; @duplexed; end

  attr_writer :duplexed

  def close_read
    super
    @readable = false
    @io.close_read unless @io.closed?
    nil
  end

  def close_write
    super
    @writable = false
    @io.close_write unless @io.closed?
    nil
  end

  def close
    super
    @io.close
    nil
  end

  private

  def unbuffered_read(length)
    if @nonblock
      @io.read_nonblock(length)
    else
      @io.sysread(length)
    end
  end

  def unbuffered_seek(offset, whence = IO::SEEK_SET)
    @io.sysseek(offset, whence)
  end

  def unbuffered_write(string)
    if @nonblock
      @io.write_nonblock(string)
    else
      @io.syswrite(string)
    end
  end

  def set_mode(mode)
    if mode.kind_of?(Integer)
      if mode & File::RDONLY == File::RDONLY
        @readable = true
      elsif mode & File::WRONLY == File::WRONLY
        @writable = true
      elsif mode & File::RDWR == File::RDWR
        @readable = true
        @writable = true
      else
        raise "invalid open mode `#{mode.to_s(16)}'"
      end
    else
      mode = 'r' if mode.nil?
      mode = mode.split(':').first

      case mode[0, 1]
      when 'r'
        @readable = true
      when 'w', 'a'
        @writable = true
      else
        raise "invalid open mode `#{mode}'"
      end

      case mode[1, 1]
      when '+'
        @readable = true
        @writable = true
      when nil, '', 'b'
        # Ignore
      else
        raise "invalid open mode `#{mode}'"
      end
    end
  end
end

class Object
  def mock_io_like(name = "io-like")
    IOWrapper.new(mock(name), 'r+')
  end

  # Replace mspec's new_io helper method to return an IO::Like wrapped IO.
  alias :__mspec_new_io :new_io
  def new_io(name, mode = "w:utf-8")
    IOWrapper.new(__mspec_new_io(name, mode), mode)
  end

  # Replace the Kernel.open method to return an IO::Like wrapped IO.
  alias :__open :open
  def open(*args, &block)
    io = IOWrapper.open(__open(*args), *args[1..-1])

    return io unless block_given?

    begin
      yield(io)
    ensure
      io.close unless io.closed?
    end
  end

  # Use a matcher that knows about IO::Like wrappers.
  alias :__mspec_output_to_fd :output_to_fd
  def output_to_fd(what, where = STDOUT)
    IOLikeOutputToFDMatcher.new what, where
  end
end

class File
  # Replace File.open to use/provide an IO::Like wrapped File.
  class << self
    alias :__file_open :open
    def open(*args, &block)
      io = IOWrapper.open(__file_open(*args), *args[1..-1])

      return io unless block_given?

      begin
        yield(io)
      ensure
        io.close unless io.closed?
      end
    end
  end
end

class IO
  # Replace IO.pipe to use/provide IO::Like wrapped endpoints.
  class << self
    alias :__pipe :pipe
    def pipe(*args, &block)
      r, w = __pipe(*args)
      r, w = IOWrapper.new(r, 'r'), IOWrapper.new(w, 'w')
      w.sync = true

      return r, w unless block_given?

      begin
        yield(r, w)
      ensure
        r.close unless r.closed?
        w.close unless w.closed?
      end
    end

    alias :__popen :popen
    def popen(*args, &block)
      io = IOWrapper.open(__popen(*args), *args[1..-1])
      io.duplexed = true

      return io unless block_given?

      begin
        yield(io)
      ensure
        io.close unless io.closed?
      end
    end
  end
end

# Remap stdout and stderr to be IO::Like wrappers (as used in some tests).
unless IOWrapper === $stdout
  $stdout = IOWrapper.new($stdout, 'w')
  $stdout.sync = true
  $stderr = IOWrapper.new($stderr, 'w')
  $stderr.sync = true
end
