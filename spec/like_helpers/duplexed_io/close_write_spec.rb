# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DuplexedIO#close_write" do
  describe "when not duplexed" do
    it "delegates to its delegate" do
      obj = mock("io")
      # Satisfy the finalizer that will call #close on this object.
      def obj.close; end
      obj.should_receive(:close).and_return(nil)
      io = IO::LikeHelpers::DuplexedIO.new(obj)
      io.close_write.should be_nil
    end

    it "short circuits after the first call" do
      obj = mock("io")
      # Satisfy the finalizer that will call #close on this object.
      def obj.close; end
      obj.should_receive(:close).and_return(nil)
      io = IO::LikeHelpers::DuplexedIO.new(obj)
      io.close_write.should be_nil
      io.close_write.should be_nil
    end

    it "does not delegate to its delegate" do
      obj = mock("io")
      obj.should_not_receive(:close)
      io = IO::LikeHelpers::DuplexedIO.new(obj, autoclose: false)
      io.close_write.should be_nil
    end

    it "returns a Symbol if its delegate does so" do
      obj = mock("io")
      # Satisfy the finalizer that will call #close on this object.
      def obj.close; end
      obj.should_receive(:close).and_return(:wait_writable)
      io = IO::LikeHelpers::DuplexedIO.new(obj)
      io.close_write.should == :wait_writable
    end
  end

  describe "when duplexed" do
    it "delegates only to the writer delegate" do
      obj_r = mock("reader_io")
      # Satisfy the finalizer that will call #close on this object.
      def obj_r.close; end
      obj_r.should_not_receive(:close)
      obj_w = mock("writer_io")
      # Satisfy the finalizer that will call #close on this object.
      def obj_w.close; end
      obj_w.should_receive(:close).and_return(nil)
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w)
      io.close_write.should be_nil
    end

    it "short circuits after the first call" do
      obj_r = mock("reader_io")
      # Satisfy the finalizer that will call #close on this object.
      def obj_r.close; end
      obj_r.should_not_receive(:close)
      obj_w = mock("writer_io")
      # Satisfy the finalizer that will call #close on this object.
      def obj_w.close; end
      obj_w.should_receive(:close).and_return(nil)
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w)
      io.close_write.should be_nil
      io.close_write.should be_nil
    end

    it "does not delegate to the writer delegate" do
      obj_r = mock("reader_io")
      obj_r.should_not_receive(:close)
      obj_w = mock("writer_io")
      obj_w.should_not_receive(:close)
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.close_write.should be_nil
    end

    it "returns a Symbol if its delegate does so" do
      obj_r = mock("reader_io")
      # Satisfy the finalizer that will call #close on this object.
      def obj_r.close; end
      obj_r.should_not_receive(:close)
      obj_w = mock("writer_io")
      # Satisfy the finalizer that will call #close on this object.
      def obj_w.close; end
      obj_w.should_receive(:close).and_return(:wait_writable)
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w)
      io.close_write.should == :wait_writable
    end
  end
end

# vim: ts=2 sw=2 et
