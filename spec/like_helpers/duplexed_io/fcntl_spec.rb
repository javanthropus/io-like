# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DuplexedIO#fcntl" do
  it "delegates to its delegate" do
    obj = mock("io")
    obj.should_receive(:fcntl).with(:foo).and_return(nil)
    io = IO::LikeHelpers::DuplexedIO.new(obj)
    io.fcntl(:foo).should be_nil
  end

  it "raises IOError when its delegate raises it" do
    obj = mock("io")
    obj.should_receive(:fcntl).with(:foo).and_raise(IOError.new('closed stream'))
    io = IO::LikeHelpers::DuplexedIO.new(obj)
    -> { io.fcntl(:foo) }.should raise_error(IOError, 'closed stream')
  end

  it "delegates to the reader delegate when not closed" do
    obj_r = mock("reader_io")
    obj_r.should_receive(:fcntl).with(:foo).and_return(nil)
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w)
    io.fcntl(:foo).should be_nil
  end

  it "delegates to the reader delegate when the write stream is closed" do
    obj_r = mock("reader_io")
    obj_r.should_receive(:fcntl).with(:foo).and_return(nil)
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close_write
    io.fcntl(:foo).should be_nil
  end

  it "delegates to the writer delegate when the read stream is closed" do
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    obj_w.should_receive(:fcntl).with(:foo).and_return(nil)
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close_read
    io.fcntl(:foo).should be_nil
  end

  it "raises IOError when both streams are closed" do
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close_read
    io.close_write
    -> { io.fcntl(:foo) }.should raise_error(IOError, 'closed stream')
  end

  it "raises IOError if the stream is closed" do
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close
    -> { io.fcntl(:foo) }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et