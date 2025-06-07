require 'io/like'
require 'io/like_helpers/delegated_io'
require 'io/like_helpers/io_wrapper'

include IO::LikeHelpers

class RunLengthCodec < IO::Like
  def initialize(delegate, autoclose: true, **kwargs)
    delegate = RLCFilter.new(delegate, autoclose: autoclose)

    super(delegate, autoclose: true, **kwargs)
  end
end

class RLCFilter < DelegatedIO
  def initialize(delegate, autoclose: true)
    if IO === delegate
      delegate = IOWrapper.new(delegate, autoclose: autoclose)
      autoclose = true
    end

    super(delegate, autoclose: autoclose)

    @run_size = 0
    @run_byte = nil
    @pending_write = false
  end

  def close
    result = flush
    return result if Symbol === result
    super
  end

  def read(length, buffer: nil, buffer_offset: 0)
    length = Integer(length)
    raise ArgumentError 'length must be at least 0' if length < 0
    if ! buffer.nil?
      if buffer_offset < 0 || buffer_offset >= buffer.bytesize
        raise ArgumentError, 'buffer_offset is not a valid buffer index'
      end
      if buffer.bytesize - buffer_offset < length
        raise ArgumentError, 'length is greater than available buffer space'
      end
    end

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
        @run_byte = byte
        @run_size = 1
        @pending_write = true
      else
        @run_size += 1
      end
    end

    length
  end

  private

  def flush
    return nil unless @pending_write
    return nil unless @run_size > 0

    result = delegate.write(@run_size.chr + @run_byte.chr)
    return result if Symbol === result
    @pending_write = false

    nil
  end
end

if $0 == __FILE__
  IO.pipe do |r, w|
    RunLengthCodec.open(w) do |rlc|
      rlc.puts('abbccc')
    end
    puts r.read.inspect
  end

  IO.pipe do |r, w|
    w.write("\u0001a\u0002b\u0003c\u0001\n")
    w.close
    RunLengthCodec.open(r) do |rlc|
      puts rlc.readline.inspect
    end
  end

  IO.pipe do |r, w|
    RunLengthCodec.open(w) do |rlc|
      rlc.puts('abbccc')
    end
    RunLengthCodec.open(r) do |rlc|
      puts rlc.read
    end
  end
end

# vim: ts=2 sw=2 et
