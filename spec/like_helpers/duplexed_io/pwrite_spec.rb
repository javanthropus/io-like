# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DuplexedIO#pwrite" do
  it "delegates to its delegate" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:pwrite).with(buffer, 2, length: 1).and_return(:result)
    io = IO::LikeHelpers::DuplexedIO.new(obj)
    io.pwrite(buffer, 2, length: 1).should == :result
  end

  it "raises IOError when its delegate raises it" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:pwrite).with(buffer, 2, length: 1).and_raise(IOError.new('closed stream'))
    io = IO::LikeHelpers::DuplexedIO.new(obj)
    -> { io.pwrite(buffer, 2, length: 1) }.should raise_error(IOError, 'closed stream')
  end

  it "raises IOError when the delegate is not writable" do
    buffer = 'foo'.b
    obj = mock("reader_io")
    obj.should_receive(:writable?).and_return(false)
    io = IO::LikeHelpers::DuplexedIO.new(obj)
    -> { io.pwrite(buffer, 2, length: 1) }.should raise_error(IOError, 'not opened for writing')
  end

  it "delegates to the writer delegate when not closed" do
    buffer = 'foo'.b
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    obj_w.should_receive(:writable?).and_return(true)
    obj_w.should_receive(:pwrite).with(buffer, 2, length: 1).and_return(:result)
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w)
    io.pwrite(buffer, 2, length: 1).should == :result
  end

  it "delegates to the writer delegate when the read stream is closed" do
    buffer = 'foo'.b
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    obj_w.should_receive(:writable?).and_return(true)
    obj_w.should_receive(:pwrite).with(buffer, 2, length: 1).and_return(:result)
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close_read
    io.pwrite(buffer, 2, length: 1).should == :result
  end

  it "raises IOError when the write stream is closed" do
    buffer = 'foo'.b
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close_write
    -> { io.pwrite(buffer, 2) }.should raise_error(IOError, 'not opened for writing')
  end

  it "raises IOError when both streams are closed" do
    buffer = 'foo'.b
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close_read
    io.close_write
    -> { io.pwrite(buffer, 2) }.should raise_error(IOError, 'closed stream')
  end

  it "raises IOError if the stream is closed" do
    buffer = 'foo'.b
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close
    -> { io.pwrite(buffer, 2) }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
