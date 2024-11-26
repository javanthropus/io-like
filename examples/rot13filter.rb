require 'io/like'
require 'io/like_helpers/delegated_io'
require 'io/like_helpers/io_wrapper'

include IO::LikeHelpers

class ROT13Filter < DelegatedIO
  def self.io_like(delegate, **kwargs, &b)
    autoclose = kwargs.delete(:autoclose) { true }
    IO::Like.open(
      new(IOWrapper.new(delegate, autoclose: autoclose)),
      **kwargs,
      &b
    )
  end

  def read(length, buffer: nil, buffer_offset: 0)
    result = super
    if buffer.nil?
      encode_rot13(result)
    else
      encode_rot13(buffer, buffer_offset: buffer_offset)
    end
    result
  end

  def write(buffer, length: buffer.bytesize)
    super(encode_rot13(buffer[0, length]), length: length)
  end

  private

  def encode_rot13(buffer, buffer_offset: 0)
    buffer_offset.upto(buffer.length - 1) do |i|
      ord = buffer[i].ord
      case ord
      when 65..90
        buffer[i] = ((ord - 52) % 26 + 65).chr
      when 97..122
        buffer[i] = ((ord - 84) % 26 + 97).chr
      end
    end
    buffer
  end
end

if $0 == __FILE__
  IO.pipe do |r, w|
    w.puts('This is a test')
    w.close
    ROT13Filter.io_like(r) do |rot13|
      puts(rot13.read)                    # -> Guvf vf n grfg
    end
  end

  IO.pipe do |r, w|
    ROT13Filter.io_like(w) do |rot13|
      rot13.puts('This is a test')
    end
    puts(r.read)                          # -> Guvf vf n grfg
  end

  IO.pipe do |r, w|
    w.puts('Guvf vf n grfg')
    w.close
    ROT13Filter.io_like(r) do |rot13|
      puts(rot13.read)                    # -> This is a test
    end
  end

  IO.pipe do |r, w|
    w.puts('This is a test')
    w.close
    ROT13Filter.io_like(r) do |rot13|
      puts(rot13.each_line.to_a.inspect)  # -> ["Guvf vf n grfg\n"]
    end
  end

  IO.pipe do |r, w|
    w.puts('Guvf vf n grfg')
    w.close
    ROT13Filter.io_like(r) do |rot13|
      puts(rot13.each_line.to_a.inspect)  # -> ["This is a test\n"]
    end
  end

  IO.pipe do |r, w|
    w.puts('This is a test')
    w.close
    IO::Like.open(ROT13Filter.new(ROT13Filter.new(IOWrapper.new(r)))) do |rot26| # ;-)
      puts(rot26.read)                    # -> This is a test
    end
  end
end

# vim: ts=2 sw=2 et
