# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DuplexedIO#seek" do
  describe "when not duplexed" do
    it "delegates to its delegate" do
      obj = mock("io")
      obj.should_receive(:seek).with(1, :CUR).and_return(:result)
      io = IO::LikeHelpers::DuplexedIO.new(obj, autoclose: false)
      io.seek(1, :CUR).should == :result
    end

    it "raises Errno:ESPIPE when its delegate raises it" do
      obj = mock("io")
      obj.should_receive(:seek).with(1, :CUR).and_raise(Errno::ESPIPE)
      io = IO::LikeHelpers::DuplexedIO.new(obj, autoclose: false)
      -> { io.seek(1, :CUR) }.should raise_error(Errno::ESPIPE)
    end

    it "raises IOError if the stream is closed" do
      obj = mock("io")
      io = IO::LikeHelpers::DuplexedIO.new(obj, autoclose: false)
      io.close
      -> { io.seek(1, :CUR) }.should raise_error(IOError, 'closed stream')
    end
  end

  describe "when duplexed" do
    it "delegates to the reader delegate when not closed" do
      obj_r = mock("reader_io")
      obj_r.should_receive(:seek).with(1, :CUR).and_return(:result)
      obj_w = mock("writer_io")
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.seek(1, :CUR).should == :result
    end

    it "raises Errno:ESPIPE when the reader delegate raises it" do
      obj_r = mock("reader_io")
      obj_r.should_receive(:seek).with(1, :CUR).and_raise(Errno::ESPIPE)
      obj_w = mock("writer_io")
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      -> { io.seek(1, :CUR) }.should raise_error(Errno::ESPIPE)
    end

    it "delegates to the reader delegate when the write stream is closed" do
      obj_r = mock("reader_io")
      obj_r.should_receive(:seek).with(1, :CUR).and_return(:result)
      obj_w = mock("writer_io")
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.close_write
      io.seek(1, :CUR).should == :result
    end

    it "delegates to the writer delegate when the read stream is closed" do
      obj_r = mock("reader_io")
      obj_w = mock("writer_io")
      obj_w.should_receive(:seek).with(1, :CUR).and_return(:result)
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.close_read
      io.seek(1, :CUR).should == :result
    end

    it "raises Errno:ESPIPE when the writer delegate raises it" do
      obj_r = mock("reader_io")
      obj_w = mock("writer_io")
      obj_w.should_receive(:seek).with(1, :CUR).and_raise(Errno::ESPIPE)
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.close_read
      -> { io.seek(1, :CUR) }.should raise_error(Errno::ESPIPE)
    end

    it "raises IOError when both streams are closed" do
      obj_r = mock("reader_io")
      obj_w = mock("writer_io")
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.close_read
      io.close_write
      -> { io.seek(1, :CUR) }.should raise_error(IOError, 'closed stream')
    end

    it "raises IOError when closed" do
      obj_r = mock("reader_io")
      obj_w = mock("writer_io")
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.close
      -> { io.seek(1, :CUR) }.should raise_error(IOError, 'closed stream')
    end
  end
end

# vim: ts=2 sw=2 et
