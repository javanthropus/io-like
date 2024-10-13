# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::BufferedIO#pread" do
  it "raises ArgumentError if length is invalid" do
    obj = mock("io")
    io = IO::LikeHelpers::BufferedIO.new(obj)
    -> { io.pread(-1, 2) }.should raise_error(ArgumentError)
  end

  it "raises ArgumentError if offset is invalid" do
    obj = mock("io")
    io = IO::LikeHelpers::BufferedIO.new(obj)
    -> { io.pread(1, -2) }.should raise_error(ArgumentError)
  end

  it "delegates to its delegate" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:pread).with(1, 2, buffer: buffer, buffer_offset: 1).and_return(:result)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.pread(1, 2, buffer: buffer, buffer_offset: 1).should == :result
  end

  it "returns a Symbol if switching to read mode does so" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:write).with(buffer).and_return(:wait_writable)
    obj.should_receive(:readable?).and_return(true)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.write(buffer).should == buffer.size
    io.pread(1, 2).should == :wait_writable
  end

  it "flushes the write buffer when switching to read mode" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:write).with(buffer).and_return(buffer.size)
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:pread).and_return("\0".b)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.write(buffer).should == buffer.size
    io.pread(1, 2).should == "\0".b
  end

  it "bypasses and preserves the read buffer" do
    buffer = 'foo'.b
    obj = mock("io")
    # HACK:
    # Mspec mocks are not able to mutate arguments, but that is necessary for
    # #read when the buffer argument is not nil as will be the case here.
    # Emulate peforming a short read.  The checks on the results of the read
    # operations on the BufferedIO instance will serve as validation that the
    # method was called.
    def obj.read(length, buffer: nil, buffer_offset: 0)
      buffer[buffer_offset, 10] = '0123456789'.b
      10
    end
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:pread).and_return('a'.b)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.read(1).should == '0'.b
    io.pread(1, 2).should == 'a'.b
    io.read(1).should == '1'.b
  end

  it "raises Argument error when the buffer offset is not a valid buffer index" do
    buffer = 'foo'.b
    obj = mock("io")
    io = IO::LikeHelpers::BufferedIO.new(obj)
    -> { io.pread(1, 2, buffer: buffer, buffer_offset: -1) }.should raise_error(ArgumentError)
    -> { io.pread(1, 2, buffer: buffer, buffer_offset: 100) }.should raise_error(ArgumentError)
  end

  it "raises Argument error when the amount to read would not fit into the given buffer" do
    buffer = 'foo'.b
    obj = mock("io")
    io = IO::LikeHelpers::BufferedIO.new(obj)
    -> { io.pread(20, 2, buffer: buffer, buffer_offset: 1) }.should raise_error(ArgumentError)
    -> { io.pread(20, 2, buffer: buffer) }.should raise_error(ArgumentError)
  end

  it "raises IOError if its delegate is not readable" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(false)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    -> { io.pread(1, 2) }.should raise_error(IOError, 'not opened for reading')
  end

  it "raises IOError if the stream is closed" do
    obj = mock("io")
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
    io.close
    -> { io.pread(1, 2) }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
