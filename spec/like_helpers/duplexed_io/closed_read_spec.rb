# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DuplexedIO#closed_read?" do
  it "returns true when the stream is closed via #close when not duplexed" do
    obj = mock("io")
    io = IO::LikeHelpers::DuplexedIO.new(obj, autoclose: false)
    io.close
    io.closed_read?.should be_true
  end

  it "returns true when the stream is closed via #close when duplexed" do
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close
    io.closed_read?.should be_true
  end

  it "returns true when the stream is closed via #close_read when not duplexed" do
    obj = mock("io")
    io = IO::LikeHelpers::DuplexedIO.new(obj, autoclose: false)
    io.close_read
    io.closed_read?.should be_true
  end

  it "returns true when the stream is closed via #close_write when not duplexed" do
    obj = mock("io")
    io = IO::LikeHelpers::DuplexedIO.new(obj, autoclose: false)
    io.close_write
    io.closed_read?.should be_true
  end

  it "returns false when the stream is closed via #close_write when duplexed" do
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close_write
    io.closed_read?.should be_false
  end

  it "returns false when the stream is not closed" do
    obj = mock("io")
    io = IO::LikeHelpers::DuplexedIO.new(obj)
    io.closed_read?.should be_false
  end
end

# vim: ts=2 sw=2 et