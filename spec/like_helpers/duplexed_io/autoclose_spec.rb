# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DuplexedIO#autoclose=" do
  describe "when not duplexed" do
    it "returns the argument given" do
      obj = mock("io")
      # Satisfy the finalizer that will call #close on this object.
      def obj.close; end
      io = IO::LikeHelpers::DuplexedIO.new(obj)
      io.send(:autoclose=, true).should be_true
      io.send(:autoclose=, false).should be_false
      io.send(:autoclose=, :foo).should == :foo
    end

    it "causes the delegate to be closed when set to true" do
      obj = mock("io")
      # Satisfy the finalizer that will call #close on this object.
      def obj.close; end
      obj.should_receive(:close).and_return(nil)
      io = IO::LikeHelpers::DuplexedIO.new(obj, autoclose: false)
      io.autoclose = true
      io.close
    end

    it "causes the delegate to not be closed when set to false" do
      obj = mock("io")
      obj.should_not_receive(:close)
      io = IO::LikeHelpers::DuplexedIO.new(obj, autoclose: false)
      io.autoclose = false
      io.close
    end

    it "raises IOError if the stream is closed" do
      obj = mock("io")
      io = IO::LikeHelpers::DuplexedIO.new(obj, autoclose: false)
      io.close
      -> { io.send(:autoclose=, false) }.should raise_error(IOError, 'closed stream')
    end
  end

  describe "when duplexed" do
    it "returns the argument given" do
      obj_r = mock("reader_io")
      # Satisfy the finalizer that will call #close on this object.
      def obj_r.close; end
      obj_w = mock("writer_io")
      # Satisfy the finalizer that will call #close on this object.
      def obj_w.close; end
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w)
      io.send(:autoclose=, true).should be_true
      io.send(:autoclose=, false).should be_false
      io.send(:autoclose=, :foo).should == :foo
    end

    it "causes the delegates to be closed when set to true" do
      obj_r = mock("reader_io")
      # Satisfy the finalizer that will call #close on this object.
      def obj_r.close; end
      obj_r.should_receive(:close).and_return(nil)
      obj_w = mock("writer_io")
      # Satisfy the finalizer that will call #close on this object.
      def obj_w.close; end
      obj_w.should_receive(:close).and_return(nil)
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.autoclose = true
      io.close
    end

    it "causes the delegates to not be closed when set to false" do
      obj_r = mock("reader_io")
      obj_r.should_not_receive(:close)
      obj_w = mock("writer_io")
      obj_w.should_not_receive(:close)
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w)
      io.autoclose = false
      io.close
    end

    it "raises IOError if the stream is closed" do
      obj_r = mock("reader_io")
      obj_w = mock("writer_io")
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.close
      -> { io.send(:autoclose=, false) }.should raise_error(IOError, 'closed stream')
    end
  end
end

describe "IO::LikeHelpers::DuplexedIO#autoclose?" do
  describe "when not duplexed" do
    it "returns the truthiness of #autoclose=" do
      obj = mock("io")
      # Satisfy the finalizer that will call #close on this object.
      def obj.close; end
      io = IO::LikeHelpers::DuplexedIO.new(obj)

      io.autoclose = true
      io.autoclose?.should be_true

      io.autoclose = false
      io.autoclose?.should be_false

      io.autoclose = :foo
      io.autoclose?.should be_true
    end

    it "raises IOError if the stream is closed" do
      obj = mock("io")
      io = IO::LikeHelpers::DuplexedIO.new(obj, autoclose: false)
      io.close
      -> { io.autoclose? }.should raise_error(IOError, 'closed stream')
    end
  end

  describe "when duplexed" do
    it "returns the truthiness of #autoclose=" do
      obj_r = mock("reader_io")
      # Satisfy the finalizer that will call #close on this object.
      def obj_r.close; end
      obj_w = mock("writer_io")
      # Satisfy the finalizer that will call #close on this object.
      def obj_w.close; end
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w)

      io.autoclose = true
      io.autoclose?.should be_true

      io.autoclose = false
      io.autoclose?.should be_false

      io.autoclose = :foo
      io.autoclose?.should be_true
    end

    it "raises IOError if the stream is closed" do
      obj_r = mock("reader_io")
      obj_w = mock("writer_io")
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.close
      -> { io.autoclose? }.should raise_error(IOError, 'closed stream')
    end
  end
end

# vim: ts=2 sw=2 et
