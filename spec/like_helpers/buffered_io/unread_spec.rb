# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

require 'io/like_helpers/buffered_io'

describe "IO::LikeHelpers::BufferedIO#unread" do
  it "raises ArgumentError if length is invalid" do
    buffer = 'foo'.b
    obj = mock("io")
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
    -> { io.unread(buffer, length: -1) }.should raise_error(ArgumentError)
  end

  it "returns nil" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
    io.unread(buffer, length: 1).should be_nil
  end

  it "places unread bytes at the head of the buffer" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
    io.unread(buffer).should be_nil
    io.read(3).should == buffer
  end

  it "raises IOError if the internal buffer is too full" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false, buffer_size: 1)
    -> { io.unread(buffer) }.should raise_error(IOError, 'insufficient buffer space for unread')
  end

  it "returns a Symbol if switching to read mode does so" do
    buffer1 = 'foo'.b
    buffer2 = 'bar'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:write).with(buffer1).and_return(:wait_writable)
    obj.should_receive(:readable?).and_return(true)
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
    io.write(buffer1).should == buffer1.size
    io.unread(buffer2).should == :wait_writable
  end

  it "flushes the write buffer when switching to read mode" do
    buffer1 = 'foo'.b
    buffer2 = 'bar'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:write).with(buffer1).and_return(buffer1.size)
    obj.should_receive(:readable?).and_return(true)
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
    io.write(buffer1).should == buffer1.size
    io.unread(buffer2).should be_nil
  end

  it "does not affect the stream position" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:seek).with(0, IO::SEEK_CUR).and_return(0).twice
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
    pos = io.seek(0, IO::SEEK_CUR)
    io.unread(buffer).should be_nil
    io.seek(0, IO::SEEK_CUR).should == pos
  end

  it "raises IOError if its delegate is not readable" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:readable?).and_return(false)
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
    -> { io.unread(buffer) }.should raise_error(IOError, 'not opened for reading')
  end

  it "raises IOError if the stream is closed" do
    buffer = 'foo'.b
    obj = mock("io")
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
    io.close
    -> { io.unread(buffer) }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
