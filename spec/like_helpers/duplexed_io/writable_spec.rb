# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DuplexedIO#writable?" do
  it "delegates to its delegate" do
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    io = IO::LikeHelpers::DuplexedIO.new(obj)
    io.writable?.should be_true
  end

  it "delegates to the writer delegate when not closed" do
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    obj_w.should_receive(:writable?).and_return(true)
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w)
    io.writable?.should be_true
  end

  it "returns false when the write stream is closed" do
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close_write
    io.writable?.should be_false
  end

  it "delegates to the writer delegate when the read stream is closed" do
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    obj_w.should_receive(:writable?).and_return(true)
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close_read
    io.writable?.should be_true
  end

  it "returns false when both streams are closed" do
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close_read
    io.close_write
    io.writable?.should be_false
  end

  it "returns false if the stream is closed" do
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close
    io.writable?.should be_false
  end
end

# vim: ts=2 sw=2 et
