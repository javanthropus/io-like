# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DuplexedIO#close" do
  describe "when not duplexed" do
    it "delegates to its delegate" do
      obj = mock("io")
      obj.should_receive(:close).and_return(nil)
      io = IO::LikeHelpers::DuplexedIO.new(obj)
      io.close.should be_nil
    end

    it "short circuits after the first call" do
      obj = mock("io")
      obj.should_receive(:close).and_return(nil)
      io = IO::LikeHelpers::DuplexedIO.new(obj)
      io.close.should be_nil
      io.close.should be_nil
    end

    it "does not delegate to its delegate" do
      obj = mock("io")
      io = IO::LikeHelpers::DuplexedIO.new(obj, autoclose: false)
      io.close.should be_nil
    end

    it "returns a Symbol if its delegate does so" do
      obj = mock("io")
      obj.should_receive(:close).and_return(:wait_readable)
      io = IO::LikeHelpers::DuplexedIO.new(obj)
      io.close.should == :wait_readable

      # Disable the finalizer that would attempt to close the mock delegate and
      # break the test.
      io.autoclose = false
    end
  end

  describe "when duplexed" do
    it "delegates to both delegates" do
      obj_r = mock("reader_io")
      obj_r.should_receive(:close).and_return(nil)
      obj_w = mock("writer_io")
      obj_w.should_receive(:close).and_return(nil)
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w)
      io.close.should be_nil
    end

    it "short circuits after the first call" do
      obj_r = mock("reader_io")
      obj_r.should_receive(:close).and_return(nil)
      obj_w = mock("writer_io")
      obj_w.should_receive(:close).and_return(nil)
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w)
      io.close.should be_nil
      io.close.should be_nil
    end

    it "does not delegate to either delegate" do
      obj_r = mock("reader_io")
      obj_r.should_not_receive(:close)
      obj_w = mock("writer_io")
      obj_w.should_not_receive(:close)
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.close.should be_nil
    end

    it "returns a Symbol if the read delegate does so" do
      obj_r = mock("reader_io")
      obj_r.should_receive(:close).and_return(:wait_readable)
      obj_w = mock("writer_io")
      obj_w.should_receive(:close).and_return(nil)
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w)
      io.close.should == :wait_readable

      # Disable the finalizer that would attempt to close the mock delegates and
      # break the test.
      io.autoclose = false
    end

    it "returns a Symbol if the write delegate does so" do
      obj_r = mock("reader_io")
      obj_w = mock("writer_io")
      obj_w.should_receive(:close).and_return(:wait_readable)
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w)
      io.close.should == :wait_readable

      # Disable the finalizer that would attempt to close the mock delegates and
      # break the test.
      io.autoclose = false
    end
  end
end

# vim: ts=2 sw=2 et
