# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DuplexedIO#closed_read?" do
  describe "when not duplexed" do
    it "returns true when the stream is closed via #close" do
      obj = mock("io")
      io = IO::LikeHelpers::DuplexedIO.new(obj, autoclose: false)
      io.close
      io.closed_read?.should be_true
    end

    it "returns true when the stream is closed via #close_read" do
      obj = mock("io")
      io = IO::LikeHelpers::DuplexedIO.new(obj, autoclose: false)
      io.close_read
      io.closed_read?.should be_true
    end

    it "returns true when the stream is closed via #close_write" do
      obj = mock("io")
      io = IO::LikeHelpers::DuplexedIO.new(obj, autoclose: false)
      io.close_write
      io.closed_read?.should be_true
    end

    it "returns false when the stream is not closed when" do
      obj = mock("io")
      io = IO::LikeHelpers::DuplexedIO.new(obj, autoclose: false)
      io.closed_read?.should be_false
    end
  end

  describe "when duplexed" do
    it "returns true when the stream is closed via #close" do
      obj_r = mock("reader_io")
      obj_w = mock("writer_io")
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.close
      io.closed_read?.should be_true
    end

    it "returns false when the stream is closed via #close_write" do
      obj_r = mock("reader_io")
      obj_w = mock("writer_io")
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.close_write
      io.closed_read?.should be_false
    end

    it "returns false when the stream is not closed" do
      obj_r = mock("reader_io")
      obj_w = mock("writer_io")
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.closed_read?.should be_false
    end
  end
end

# vim: ts=2 sw=2 et
