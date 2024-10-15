# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::BufferedIO#read" do
  before :each do
    @data = 'foo'.b * 100
    @tmpfile = tmp("tmp_BufferedIO_read")
    tmpio = File.open(@tmpfile, 'w+b')
    tmpio.write(@data)
    tmpio.rewind
    @delegate = IO::LikeHelpers::IOWrapper.new(tmpio)
  end

  after :each do
    @delegate.close
    rm_r @tmpfile
  end

  it "returns the number of bytes read when the buffer argument is provided" do
    io = IO::LikeHelpers::BufferedIO.new(@delegate)
    io.read(1, buffer: "\0").should == 1
  end

  it "inserts bytes at the index specified by the buffer_offset argument" do
    buffer = 'bar'.b
    (expected = buffer.dup)[1] = @data[0]
    io = IO::LikeHelpers::BufferedIO.new(@delegate)
    io.read(1, buffer: buffer, buffer_offset: 1).should == 1
    buffer.should == expected
  end

  it "defaults the buffer argument to nil and returns a new buffer" do
    io = IO::LikeHelpers::BufferedIO.new(@delegate)
    io.read(1).should == @data[0]
  end

  it "returns a short read if not enough data is available in the buffer" do
    io = IO::LikeHelpers::BufferedIO.new(@delegate, buffer_size: 10)
    io.read(1)
    io.read(100).should == @data[1, 9]
  end

  it "returns a Symbol if switching to read mode does so" do
    buffer = 'bar'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:write).with(buffer).and_return(:wait_writable)
    obj.should_receive(:readable?).and_return(true)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.write(buffer).should == buffer.size
    io.read(1).should == :wait_writable
  end

  it "flushes the write buffer when switching to read mode" do
    buffer = 'bar'.b
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
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).and_return(:wait_readable)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.read(1).should == :wait_readable
  end

  it "does not modify the given buffer when the delegate returns a Symbol" do
    buffer = 'bar'.b
    expected = buffer.dup
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).and_return(:wait_readable)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.read(1, buffer: buffer)
    buffer.should == expected
  end

  it "raises ArgumentError if length is invalid" do
    io = IO::LikeHelpers::BufferedIO.new(@delegate)
    -> { io.read(-1) }.should raise_error(ArgumentError)
  end

  it "raises Argument error when the buffer offset is not a valid buffer index" do
    buffer = 'foo'.b
    io = IO::LikeHelpers::BufferedIO.new(@delegate)
    -> { io.read(1, buffer: buffer, buffer_offset: -1) }.should raise_error(ArgumentError)
    -> { io.read(1, buffer: buffer, buffer_offset: 100) }.should raise_error(ArgumentError)
  end

  it "raises Argument error when the amount to read would not fit into the given buffer" do
    buffer = 'foo'.b
    io = IO::LikeHelpers::BufferedIO.new(@delegate)
    -> { io.read(20, buffer: buffer, buffer_offset: 1) }.should raise_error(ArgumentError)
    -> { io.read(20, buffer: buffer) }.should raise_error(ArgumentError)
  end

  it "raises EOFError if reading begins at end of file" do
    @delegate.seek(0, IO::SEEK_END)
    io = IO::LikeHelpers::BufferedIO.new(@delegate)
    -> { io.read(1) }.should raise_error(EOFError)
  end

  it "raises IOError if its delegate is not readable" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(false)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    -> { io.read(1) }.should raise_error(IOError, 'not opened for reading')
  end

  it "raises IOError if the stream is closed" do
    io = IO::LikeHelpers::BufferedIO.new(@delegate)
    io.close
    -> { io.read(1) }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
