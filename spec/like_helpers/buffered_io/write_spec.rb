# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::BufferedIO#write" do
  it "raises ArgumentError if length is invalid" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    -> { io.write(buffer, length: -1) }.should raise_error(ArgumentError)
  end

  it "returns the number of bytes written" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.write(buffer, length: 1).should == 1
  end

  it "returns less than total given bytes when the internal buffer is filled" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    io = IO::LikeHelpers::BufferedIO.new(obj, buffer_size: 2)
    io.write(buffer).should == 2
  end

  it "defaults the number of bytes to write to the number of bytes in the buffer" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.write(buffer).should == buffer.size
  end

  it "delegates to its delegate when the internal buffer is full" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:write).with(buffer).and_return(buffer.size)
    io = IO::LikeHelpers::BufferedIO.new(obj, buffer_size: 3)
    io.write(buffer).should == buffer.size
    io.write(buffer).should == buffer.size
  end

  it "returns a Symbol when the delegate does so" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:write).with(buffer).and_return(:wait_writable)
    io = IO::LikeHelpers::BufferedIO.new(obj, buffer_size: 3)
    io.write(buffer).should == buffer.size
    io.write(buffer).should == :wait_writable
  end

  it "returns successfully when switching from read to write mode on non-seekable IO" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).and_return(3)
    obj.should_receive(:writable?).and_return(true)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.read(1)
    io.write(buffer, length: 1).should == 1
  end

  it "rewinds to the buffered read position when switching from read to write mode on seekable IO" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).and_return(3)
    obj.should_receive(:seek).with(-2, IO::SEEK_CUR).and_return(1)
    obj.should_receive(:writable?).and_return(true)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.read(1)
    io.write(buffer, length: 1).should == 1
  end

  it "raises IOError if its delegate is not writable" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(false)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    -> { io.write(buffer) }.should raise_error(IOError, 'not opened for writing')
  end

  it "raises IOError if the stream is closed" do
    buffer = 'foo'.b
    obj = mock("io")
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
    io.close
    -> { io.write(buffer) }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
