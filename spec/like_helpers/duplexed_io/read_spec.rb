# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DuplexedIO#read" do
  it "delegates to its delegate" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).with(1, buffer: buffer).and_return(:result)
    io = IO::LikeHelpers::DuplexedIO.new(obj)
    io.read(1, buffer: buffer).should == :result
  end

  it "defaults the buffer to nil" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).with(1, buffer: nil).and_return(:result)
    io = IO::LikeHelpers::DuplexedIO.new(obj)
    io.read(1).should == :result
  end

  it "raises IOError when its delegate raises it" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).with(1, buffer: buffer).and_raise(IOError.new('closed stream'))
    io = IO::LikeHelpers::DuplexedIO.new(obj)
    -> { io.read(1, buffer: buffer) }.should raise_error(IOError, 'closed stream')
  end

  it "raises IOError when the delegate is not readable" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(false)
    io = IO::LikeHelpers::DuplexedIO.new(obj)
    -> { io.read(1) }.should raise_error(IOError, 'not opened for reading')
  end

  it "delegates to the reader delegate when not closed" do
    buffer = 'foo'.b
    obj_r = mock("reader_io")
    obj_r.should_receive(:readable?).and_return(true)
    obj_r.should_receive(:read).with(1, buffer: buffer).and_return(:result)
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w)
    io.read(1, buffer: buffer).should == :result
  end

  it "delegates to the reader delegate when the write stream is closed" do
    buffer = 'foo'.b
    obj_r = mock("reader_io")
    obj_r.should_receive(:readable?).and_return(true)
    obj_r.should_receive(:read).with(1, buffer: buffer).and_return(:result)
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close_write
    io.read(1, buffer: buffer).should == :result
  end

  it "raises IOError when the read stream is closed" do
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close_read
    -> { io.read(1) }.should raise_error(IOError, 'not opened for reading')
  end

  it "raises IOError when both streams are closed" do
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close_read
    io.close_write
    -> { io.read(1) }.should raise_error(IOError, 'closed stream')
  end

  it "raises IOError if the stream is closed" do
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close
    -> { io.read(1) }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
