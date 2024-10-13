# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::BufferedIO#refill" do
  it "returns a Symbol if switching to read mode does so" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:write).with(buffer).and_return(:wait_writable)
    obj.should_receive(:readable?).and_return(true)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.write(buffer).should == buffer.size
    io.refill.should == :wait_writable
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
    io.refill.should == 3
  end

  it "returns a Symbol if reading from the delegate does so" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).and_return(:wait_readable)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.refill.should == :wait_readable
  end

  it "returns the number of bytes read from the delegate" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).and_return(3)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.refill.should == 3
  end

  it "reads from the delegate again if the read buffer is not full" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).and_return(3, 4)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.refill.should == 3
    io.refill.should == 4
  end

  it "does not read from the delegate again if the read buffer is full" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).and_return(10)
    io = IO::LikeHelpers::BufferedIO.new(obj, buffer_size: 10)
    io.refill.should == 10
    io.refill.should == 0
  end

  it "fills the read buffer after a partial read" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).and_return(10, 1)
    io = IO::LikeHelpers::BufferedIO.new(obj, buffer_size: 10)
    io.read(1)
    io.refill.should == 1
  end

  it "raises EOFError if reading begins at end of file" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).and_raise(EOFError.new)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    -> { io.refill }.should raise_error(EOFError)
  end

  it "raises IOError if its delegate is not readable" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(false)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    -> { io.refill }.should raise_error(IOError, 'not opened for reading')
  end

  it "raises IOError if the stream is closed" do
    obj = mock("io")
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
    io.close
    -> { io.refill }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
