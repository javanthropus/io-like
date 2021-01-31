# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::BufferedIO#read" do
  it "raises ArgumentError if length is invalid" do
    obj = mock("io")
    io = IO::LikeHelpers::BufferedIO.new(obj)
    -> { io.read(-1) }.should raise_error(ArgumentError)
  end

  it "returns the number of bytes read when the buffer argument is provided" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).and_return(100)
    io = IO::LikeHelpers::BufferedIO.new(obj, buffer_size: 100)
    io.read(1, buffer: '').should == 1
  end

  it "defaults the buffer argument to nil and returns a new buffer" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).with(100, buffer: "\0".b * 100).and_return(100)
    io = IO::LikeHelpers::BufferedIO.new(obj, buffer_size: 100)
    io.read(1).should == "\0"
  end

  it "returns a Symbol if switching to read mode does so" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:write).with(buffer).and_return(:wait_writable)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.write(buffer).should == buffer.size
    io.read(1).should == :wait_writable
  end

  it "flushes the write buffer when switching to read mode" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:write).with(buffer).and_return(buffer.size)
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).and_return(3)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.write(buffer).should == buffer.size
    io.read(1)
  end

  it "returns a Symbol if reading from the delegate does so" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).and_return(:wait_readable)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.read(1).should == :wait_readable
  end

  it "delegates to its delegate" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).and_return(1)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.read(1, buffer: buffer).should == 1
  end

  it "fills the internal buffer from its delegate" do
    IO.pipe do |r, w|
      w.write('bar' * 3)
      w.close
      io = IO::LikeHelpers::BufferedIO.new(IO::LikeHelpers::IOWrapper.new(r))
      io.read(1).should == 'b'
    end
  end

  it "uses the internal buffer for subsequent reads" do
    IO.pipe do |r, w|
      w.write('bar' * 3)
      w.close
      io = IO::LikeHelpers::BufferedIO.new(IO::LikeHelpers::IOWrapper.new(r))
      io.read(1).should == 'b'
      io.read(2).should == 'ar'
    end
  end

  it "returns a short read if the request is larger than buffered data" do
    IO.pipe do |r, w|
      w.write('bar' * 3)
      w.close
      io = IO::LikeHelpers::BufferedIO.new(IO::LikeHelpers::IOWrapper.new(r), buffer_size: 3)
      io.read(100).should == 'bar'
    end
  end

  it "returns a short read if end of file is reached after reading some data" do
    IO.pipe do |r, w|
      w.write('bar' * 3)
      w.close
      io = IO::LikeHelpers::BufferedIO.new(IO::LikeHelpers::IOWrapper.new(r))
      io.read(100).should == 'bar' * 3
    end
  end

  it "raises EOF error if reading begins at end of file" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).and_raise(EOFError.new)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    -> { io.read(1) }.should raise_error(EOFError)
  end

  it "raises IOError if its delegate is not readable" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(false)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    -> { io.read(1) }.should raise_error(IOError, 'not opened for reading')
  end

  it "raises IOError if the stream is closed" do
    obj = mock("io")
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
    io.close
    -> { io.read(1) }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
