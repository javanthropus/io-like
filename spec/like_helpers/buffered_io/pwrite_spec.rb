# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::BufferedIO#pwrite" do
  it "raises ArgumentError if length is invalid" do
    buffer = 'foo'.b
    obj = mock("io")
    io = IO::LikeHelpers::BufferedIO.new(obj)
    -> { io.pwrite(buffer, 2, length: -1) }.should raise_error(ArgumentError)
  end

  it "raises ArgumentError if offset is invalid" do
    buffer = 'foo'.b
    obj = mock("io")
    io = IO::LikeHelpers::BufferedIO.new(obj)
    -> { io.pwrite(buffer, -2, length: 1) }.should raise_error(ArgumentError)
  end

  it "defaults the number of bytes to write to the number of bytes in the buffer" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:pwrite).with(buffer, 2, length: buffer.size).and_return(buffer.size)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.pwrite(buffer, 2).should == buffer.size
  end

  it "delegates to its delegate" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:pwrite).with(buffer, 2, length: 1).and_return(:result)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.pwrite(buffer, 2, length: 1).should == :result
  end

  it "flushes the read buffer when switching to write mode" do
    read_buffer = String.new("\0".b * 100)
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).with(100, buffer: read_buffer, buffer_offset: 0).and_return(read_buffer.size).twice
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:pwrite).with(buffer, 2, length: buffer.size).and_return(buffer.size)
    io = IO::LikeHelpers::BufferedIO.new(obj, buffer_size: read_buffer.size)
    io.read(1).should == "\0"
    io.pwrite(buffer, 2).should == buffer.size
    io.read(1).should == "\0"
  end

  it "bypasses and preserves the write buffer" do
    buffer = 'foo'.b
    obj = mock("io")
    # HACK:
    # Real methods that manipulate object state are needed in order to verify
    # the order and content of write operations performed by BufferedIO.
    def obj.write(buffer, length: buffer.size)
      content[0, length] = buffer
      length
    end
    def obj.pwrite(buffer, offset, length: buffer.size)
      content[offset, length] = buffer
      length
    end
    def obj.content
      @content ||= String.new("\0".b * 5)
    end
    obj.should_receive(:writable?).and_return(true)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.write(buffer).should == buffer.size
    io.pwrite(buffer, 2).should == buffer.size
    io.flush
    obj.content.should == 'foooo'.b
  end

  it "raises IOError if its delegate is not writable" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(false)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    -> { io.pwrite(buffer, 2) }.should raise_error(IOError, 'not opened for writing')
  end

  it "raises IOError if the stream is closed" do
    buffer = 'foo'.b
    obj = mock("io")
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
    io.close
    -> { io.pwrite(buffer, 2) }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
