require 'io/like'
require 'io/like_helpers/buffered_io'
require 'io/like_helpers/delegated_io'
require 'io/like_helpers/io_wrapper'

include IO::LikeHelpers

class FilteredIO < DelegatedIO
  def self.open_iolike(*args, **kwargs)
    iolike = new_iolike(*args, **kwargs)
    return iolike unless block_given?

    begin
      yield(iolike)
    ensure
      iolike.close
    end
  end

  def self.new_iolike(
    io,
    autoclose: true,
    binmode: false,
    internal_encoding: nil,
    external_encoding: nil,
    sync: false,
    newline: :lf
  )
    IO::Like.new(
      BufferedIO.new(
        new(IOWrapper.new(io), autoclose: autoclose)
      ),
      autoclose: true,
      binmode: binmode,
      internal_encoding: internal_encoding,
      external_encoding: external_encoding,
      sync: sync,
      newline: newline
    )
  end

  def read(length, buffer: nil)
    raise IOError, 'closed stream' if closed?
    raise IOError, 'not opened for reading'
  end

  def readable?
    false
  end

  def seek(amount, whence = IO::SEEK_SET)
    raise IOError, 'closed stream' if closed?
    raise Errno::ESPIPE
  end

  def seekable?
    false
  end

  def write(buffer, length: buffer.bytesize)
    raise IOError, 'closed stream' if closed?
    raise IOError, 'not opened for writing'
  end

  def writable?
    false
  end
end

class RunLengthEncodingReader < FilteredIO
  def initialize(delegate, autoclose: true)
    super(delegate, autoclose: autoclose)

    @run_size = 0
    @run_byte = nil
  end

  def read(length, buffer: nil)
    length = Integer(length)
    raise ArgumentError 'length must be at least 0' if length < 0

    raise IOError, 'closed stream' if closed?
    raise IOError, 'not opened for reading' unless readable?

    if @run_size == 0
      @run_byte = nil
      result = delegate.read(1)
      return result if Symbol === result
      @run_size = result.ord
    end

    if @run_byte.nil?
      begin
        result = delegate.read(1)
      rescue EOFError
        raise 'truncated data'
      end
      return result if Symbol === result
      @run_byte = result
    end

    length = @run_size if @run_size < length
    content = @run_byte * length
    @run_size -= length
    return content if buffer.nil?

    buffer[0, length] = content
    return length
  end

  def readable?
    true
  end
end

class RunLengthEncodingWriter < FilteredIO
  def initialize(delegate, autoclose: true)
    super(delegate, autoclose: autoclose)

    @run_size = 0
    @run_byte = nil
  end

  def close
    result = flush
    return result if Symbol === result
    super
  end

  def write(buffer, length: buffer.bytesize)
    raise IOError, 'closed stream' if closed?
    raise IOError, 'not opened for writing' unless writable?

    total_written = 0
    buffer[0, length].each_byte do |byte|
      if byte != @run_byte || @run_size == 255
        result = flush
        if Symbol === result
          return total_written if total_written > 0
          return result
        end
        @pending = 2
        @run_byte = byte
        @run_size = 1
      else
        @run_size += 1
      end
    end

    length
  end

  def writable?
    true
  end

  private

  def flush
    return nil unless @run_size > 0

    if @pending == 2
      result = delegate.write(@run_size.chr)
      return result if Symbol === result
      @pending -= 1
    end
    if @pending == 1
      result = delegate.write(@run_byte.chr)
      return result if Symbol === result
      @pending -= 1
    end

    nil
  end
end

if $0 == __FILE__ then
  IO.pipe do |r, w|
    RunLengthEncodingWriter.open_iolike(w) do |rle|
      rle.puts('abbccc')
    end
    puts r.read.inspect
  end

  IO.pipe do |r, w|
    w.write("\u0001a\u0002b\u0003c\u0001\n")
    w.close
    RunLengthEncodingReader.open_iolike(r) do |rle|
      puts rle.readline.inspect
    end
  end
end

# vim: ts=2 sw=2 et
