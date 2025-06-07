require 'io/like'
require 'io/like_helpers/delegated_io'
require 'io/like_helpers/io_wrapper'

include IO::LikeHelpers

class ROT13IO < IO::Like
  def initialize(delegate, autoclose: true, **kwargs)
    delegate = delegate.rot13_filter if self.class === delegate
    @rot13_filter = ROT13Filter.new(delegate, autoclose: autoclose)

    super(@rot13_filter, autoclose: true, **kwargs)
  end

  protected

  def rot13_filter
    flush if writable?
    @rot13_filter
  end
end

class ROT13Filter < DelegatedIO
  def initialize(delegate, autoclose: true, **kwargs)
    if IO === delegate
      delegate = IOWrapper.new(delegate, autoclose: autoclose)
      autoclose = true
    end

    super(delegate, autoclose: autoclose, **kwargs)
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
  # Write encoded content to stdout, leaving stdout open after completion.
  ROT13IO.open(STDOUT, autoclose: false) do |rot13|
    rot13.puts('This is a test. 1234!')   # -> Guvf vf n grfg. 1234!
  end

  # Decode content from an input stream and read as lines.
  IO.pipe do |r, w|
    w.puts('This is a test. 1234!')
    w.puts('Guvf vf n grfg. 4567!')
    w.close
    ROT13IO.open(r) do |rot13|
      puts(rot13.each_line.to_a.inspect)  # -> ["Guvf vf n grfg. 1234!\n", "This is a test. 4567!\n"]
    end
  end

  # Double decode content (noop) and dump to stdout using IO.copy_stream.
  IO.pipe do |r, w|
    w.puts('This is a test. 1234!')
    w.close
    ROT13IO.open(r) do |rot13|
      ROT13IO.open(rot13) do |rot26|
        IO.copy_stream(rot26, STDOUT)     # -> This is a test. 1234!
      end
    end
  end
end

# vim: ts=2 sw=2 et
