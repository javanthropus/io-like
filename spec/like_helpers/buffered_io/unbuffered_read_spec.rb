# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::BufferedIO#unbuffered_read" do
  it "delegates to its delegate" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).with(1, buffer: buffer).and_return(:result)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.unbuffered_read(1, buffer: buffer).should == :result
  end

  it "defaults the buffer argument to nil and returns a new buffer" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).with(1, buffer: nil).and_return(:result)
    io = IO::LikeHelpers::BufferedIO.new(obj, buffer_size: 100)
    io.unbuffered_read(1).should == :result
  end

  it "bypasses the internal read buffer" do
    buffer1 = 'foo'.b
    buffer2 = 'bar'.b
    IO.pipe do |r, w|
      w.write(buffer1)
      w.write(buffer2)
      w.close
      io = IO::LikeHelpers::BufferedIO.new(IO::LikeHelpers::IOWrapper.new(r), buffer_size: 3)
      io.read(1).should == buffer1[0]
      io.unbuffered_read(3).should == buffer2
    end
  end

  it "does not modify the internal write buffer" do
    buffer1 = 'foo'.b
    buffer2 = 'bar'.b
    filename = tmp('buffered_io_unbuffered_read')
    begin
      File.write(filename, buffer1)
      File.open(filename, 'r+') do |f|
        io = IO::LikeHelpers::BufferedIO.new(IO::LikeHelpers::IOWrapper.new(f))
        io.write(buffer2).should == buffer2.size
        io.unbuffered_read(3).should == buffer1
        io.close
      end
      File.read(filename).should == buffer1 + buffer2
    ensure
      rm_r(filename)
    end
  end

  it "raises IOError if its delegate is not readable" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(false)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    -> { io.unbuffered_read(1) }.should raise_error(IOError, 'not opened for reading')
  end

  it "raises IOError if the stream is closed" do
    obj = mock("io")
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
    io.close
    -> { io.unbuffered_read(1) }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
