# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DuplexedIO#to_io" do
  describe "when not duplexed" do
    it "delegates to its delegate" do
      obj = mock("io")
      obj.should_receive(:to_io).and_return(:result)
      io = IO::LikeHelpers::DuplexedIO.new(obj, autoclose: false)
      io.to_io.should == :result
    end

    it "raises IOError when its delegate raises it" do
      obj = mock("io")
      obj.should_receive(:to_io).and_raise(IOError.new('closed stream'))
      io = IO::LikeHelpers::DuplexedIO.new(obj, autoclose: false)
      -> { io.to_io }.should raise_error(IOError, 'closed stream')
    end

    it "raises IOError if the stream is closed" do
      obj = mock("io")
      io = IO::LikeHelpers::DuplexedIO.new(obj, autoclose: false)
      io.close
      -> { io.to_io }.should raise_error(IOError, 'closed stream')
    end
  end

  describe "when duplexed" do
    it "delegates to the reader delegate when not closed" do
      obj_r = mock("reader_io")
      obj_r.should_receive(:to_io).and_return(:result)
      obj_w = mock("writer_io")
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.to_io.should == :result
    end

    it "raises IOError when the reader delegate raises it" do
      obj_r = mock("reader_io")
      obj_r.should_receive(:to_io).and_raise(IOError.new('closed stream'))
      obj_w = mock("writer_io")
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      -> { io.to_io }.should raise_error(IOError, 'closed stream')
    end

    it "delegates to the reader delegate when the write stream is closed" do
      obj_r = mock("reader_io")
      obj_r.should_receive(:to_io).and_return(:result)
      obj_w = mock("writer_io")
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.close_write
      io.to_io.should == :result
    end

    it "delegates to the writer delegate when the read stream is closed" do
      obj_r = mock("reader_io")
      obj_w = mock("writer_io")
      obj_w.should_receive(:to_io).and_return(:result)
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.close_read
      io.to_io.should == :result
    end

    it "raises IOError when the writer delegate raises it" do
      obj_r = mock("reader_io")
      obj_w = mock("writer_io")
      obj_w.should_receive(:to_io).and_raise(IOError.new('closed stream'))
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.close_read
      -> { io.to_io }.should raise_error(IOError, 'closed stream')
    end

    it "raises IOError when both streams are closed" do
      obj_r = mock("reader_io")
      obj_w = mock("writer_io")
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.close_read
      io.close_write
      -> { io.to_io }.should raise_error(IOError, 'closed stream')
    end

    it "raises IOError if the stream is closed" do
      obj_r = mock("reader_io")
      obj_w = mock("writer_io")
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.close
      -> { io.to_io }.should raise_error(IOError, 'closed stream')
    end
  end
end

# vim: ts=2 sw=2 et
