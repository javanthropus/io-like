# encoding: UTF-8
require 'io/like'

class ROT13Filter
  include IO::Like

  def self.open(delegate_io)
    filter = new(delegate_io)
    return filter unless block_given?

    begin
      yield(filter)
    ensure
      filter.close unless filter.closed?
    end
  end

  def initialize(delegate_io)
    @delegate_io = delegate_io
  end

  private

  def encode_rot13(string)
    result = string.dup
    0.upto(result.length) do |i|
      case result[i]
      when 65..90
        result[i] = (result[i] - 52) % 26 + 65
      when 97..122
        result[i] = (result[i] - 84) % 26 + 97
      end
    end
    result
  end

  def unbuffered_read(length)
    encode_rot13(@delegate_io.sysread(length))
  end

  def unbuffered_seek(offset, whence = IO::SEEK_SET)
    @delegate_io.sysseek(offset, whence)
  end

  def unbuffered_write(string)
    @delegate_io.syswrite(encode_rot13(string))
  end
end

if $0 == __FILE__ then
  File.open('normal_file.txt', 'w') do |f|
    f.puts('This is a test')
  end

  File.open('rot13_file.txt', 'w') do |f|
    ROT13Filter.open(f) do |rot13|
      rot13.puts('This is a test')
    end
  end

  File.open('normal_file.txt') do |f|
    ROT13Filter.open(f) do |rot13|
      puts(rot13.read)                      # -> Guvf vf n grfg
    end
  end

  File.open('rot13_file.txt') do |f|
    ROT13Filter.open(f) do |rot13|
      puts(rot13.read)                      # -> This is a test
    end
  end

  File.open('normal_file.txt') do |f|
    ROT13Filter.open(f) do |rot13|
      rot13.pos = 5
      puts(rot13.read)                      # -> vf n grfg
    end
  end

  File.open('rot13_file.txt') do |f|
    ROT13Filter.open(f) do |rot13|
      rot13.pos = 5
      puts(rot13.read)                      # -> is a test
    end
  end

  File.open('normal_file.txt') do |f|
    ROT13Filter.open(f) do |rot13|
      ROT13Filter.open(rot13) do |rot26|    # ;-)
        puts(rot26.read)                    # -> This is a test
      end
    end
  end
end
