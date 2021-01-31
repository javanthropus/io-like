# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::BufferedIO#unbuffered_seek" do
  it "delegates to its delegate" do
    obj = mock("io")
    obj.should_receive(:seek).with(1, :CUR).and_return(:result)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.unbuffered_seek(1, :CUR).should == :result
  end

  it "defaults the starting point to be absolute" do
    obj = mock("io")
    obj.should_receive(:seek).with(1, IO::SEEK_SET).and_return(:result)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.unbuffered_seek(1).should == :result
  end

  it "does not modify the internal write buffer" do
    buffer1 = 'foo'.b
    buffer2 = 'bar'.b
    filename = tmp('buffered_io_unbuffered_seek')
    begin
      File.write(filename, buffer1)
      File.open(filename, 'r+') do |f|
        io = IO::LikeHelpers::BufferedIO.new(IO::LikeHelpers::IOWrapper.new(f))
        io.write(buffer2).should == buffer2.size
        io.unbuffered_seek(1, IO::SEEK_SET).should == 1
        io.close
      end
      File.read(filename).should == buffer1[0] + buffer2
    ensure
      rm_r(filename)
    end
  end

  it "does not modify the internal read buffer" do
    buffer1 = 'foo'.b
    buffer2 = 'bar'.b
    filename = tmp('buffered_io_unbuffered_seek')
    begin
      File.write(filename, buffer1)
      File.open(filename, 'r+') do |f|
        io = IO::LikeHelpers::BufferedIO.new(IO::LikeHelpers::IOWrapper.new(f))
        io.read(1) == buffer1[0]
        io.unbuffered_seek(1, IO::SEEK_SET).should == 1
        io.read(2) == buffer1[2, 2]
      end
    ensure
      rm_r(filename)
    end
  end

  it "raises IOError if the stream is closed" do
    obj = mock("io")
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
    io.close
    -> { io.unbuffered_seek(1) }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
