# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DuplexedIO#inspect" do
  describe "when not duplexed" do
    it "emits a string representation of the stream" do
      obj = mock("io")
      obj.should_receive(:inspect).and_return("delegate_obj")
      io = IO::LikeHelpers::DuplexedIO.new(obj, autoclose: false)
      io.inspect.should == "<IO::LikeHelpers::DuplexedIO:delegate_obj>"
    end

    it "emits a string representation of the stream when the stream is closed" do
      obj = mock("io")
      obj.should_receive(:inspect).and_return("delegate_obj")
      io = IO::LikeHelpers::DuplexedIO.new(obj, autoclose: false)
      io.close
      io.inspect.should == "<IO::LikeHelpers::DuplexedIO:delegate_obj (closed)>"
    end
  end

  describe "when duplexed" do
    it "emits a string representation of the stream" do
      obj_r = mock("reader_io")
      obj_r.should_receive(:inspect).and_return("reader_delegate")
      obj_w = mock("writer_io")
      obj_w.should_receive(:inspect).and_return("writer_delegate")
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.inspect.should == "<IO::LikeHelpers::DuplexedIO:reader_delegate, writer_delegate>"
    end

    it "emits a string representation of the stream when the writer stream is closed" do
      obj_r = mock("reader_io")
      obj_r.should_receive(:inspect).and_return("reader_delegate")
      obj_w = mock("writer_io")
      obj_w.should_not_receive(:inspect)
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.close_write
      io.inspect.should == "<IO::LikeHelpers::DuplexedIO:reader_delegate>"
    end

    it "emits a string representation of the stream when the reader stream is closed" do
      obj_r = mock("reader_io")
      obj_r.should_not_receive(:inspect)
      obj_w = mock("writer_io")
      obj_w.should_receive(:inspect).and_return("writer_delegate")
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.close_read
      io.inspect.should == "<IO::LikeHelpers::DuplexedIO:writer_delegate>"
    end

    it "emits a string representation of the stream when the stream is closed" do
      obj_r = mock("reader_io")
      obj_r.should_receive(:inspect).and_return("reader_delegate")
      obj_w = mock("writer_io")
      obj_w.should_not_receive(:inspect)
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.close
      io.inspect.should == "<IO::LikeHelpers::DuplexedIO:reader_delegate (closed)>"
    end
  end
end

# vim: ts=2 sw=2 et
