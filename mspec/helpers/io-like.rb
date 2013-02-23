# encoding: UTF-8
require 'io/like'
require 'fcntl'

class IOWrapper
  include IO::Like

  def self.open(io)
    iow = new(io)
    return iow unless block_given?
    begin
      yield(iow)
    ensure
      iow.close unless iow.closed?
    end
  end

  def initialize(io)
    @io = io
  end


  def dup
      duped = super
      duped.reopen(@io.dup)
      duped
  end
  
  def reopen(io)
      @io = io
  end

  private
     
  def unbuffered_read(length)
    @io.sysread(length)
  end

  def unbuffered_seek(offset, whence = IO::SEEK_SET)
    @io.sysseek(offset, whence)
  end

  def unbuffered_write(string)
    @io.syswrite(string)
  end
end

class FileIOWrapper < IOWrapper
    def initialize(fileio)
        super(fileio)
        flags = fileio.fcntl(Fcntl::F_GETFL)
        @readable = (flags & Fcntl::O_WRONLY == 0)
        @writable = (flags & (Fcntl::O_RDWR | Fcntl::O_WRONLY) != 0)
        @duplexed = false
        @external_encoding = fileio.external_encoding if fileio.respond_to?(:external_encoding)
        # one sysread spec needs fill_size 0, but then we wouldn't be testing our buffering
        #self.fill_size=0 if readable?
    end

    def __io_like__close_read()
        super()
        @io.close_read() rescue nil
    end

    def __io_like__close_write()
        super()
        @io.close_write() rescue nil
    end

    def flush()
        super
        @io.flush
    end

    def fsync()
        flush()
        @io.fsync
    end
  
    def nonblock=(nb)
      flags = @io.fcntl(Fcntl::F_GETFL)
      new_flags = nb ? flags | Fcntl::O_NONBLOCK : flags & ~Fcntl::O_NONBLOCK
      @io.fcntl(Fcntl::F_SETFL,new_flags)
    end

    def readable?; @readable; end
    def writable?; @writable; end
    def duplexed?; @duplexed; end

    def path
        @io.path
    end

end

class PipeStreamIOWrapper < FileIOWrapper
    def initialize(io)
        super(io)
        @duplexed=true
        self.sync=true
    end
end

class Object

    def mock_io_like(name="io-like")
      io = mock(name)
      io.extend(IO::Like)
      io
    end

    # Replace mspec's new_io helper method
    alias :__mspec_new_io :new_io
    def new_io(name, mode="w:utf-8")
       FileIOWrapper.new(__mspec_new_io(name,mode))
    end

    # And Kernel.open...
    alias :__open :open
    def open(*args,&block)
        if block_given?
            __open(*args) { |f| FileIOWrapper.open(f,&block) }
        else
           FileIOWrapper.new(__open(*args))
        end
    end
end

class File

    # replace File.open with wrapped IO-likes
    class << self
        alias :__file_open :open
        
        def open(*args,&block)
           if block_given?
                __file_open(*args) { |f| FileIOWrapper.open(f,&block) }
           else
                FileIOWrapper.open(__file_open(*args))
           end
        end
    end
end

class IO
    # replace IO.pipe with wrapped IO-likes
    class << self
       alias :__pipe :pipe

       def pipe(*args,&block)
           if block_given?
              __pipe(*args) do |r,w|
                  yield PipeStreamIOWrapper.new(r), PipeStreamIOWrapper.new(w)
              end
           else
              r,w = __pipe(*args)
              return PipeStreamIOWrapper.new(r), PipeStreamIOWrapper.new(w)
           end
       end
    end
end

