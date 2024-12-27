# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DuplexedIO#close_on_exec=" do
  describe "when not duplexed" do
    it "delegates to its delegate" do
      obj = mock("io")
      obj.should_receive(:close_on_exec=).with(true).and_return(:nil)
      io = IO::LikeHelpers::DuplexedIO.new(obj, autoclose: false)
      io.send(:close_on_exec=, true).should be_true
    end

    it "raises IOError when its delegate raises it" do
      obj = mock("io")
      obj.should_receive(:close_on_exec=).with(true).and_raise(IOError.new('closed stream'))
      io = IO::LikeHelpers::DuplexedIO.new(obj, autoclose: false)
      -> { io.send(:close_on_exec=, true) }.should raise_error(IOError, 'closed stream')
    end
  end

  describe "when duplexed" do
    it "delegates to both delegates" do
      obj_r = mock("reader_io")
      obj_r.should_receive(:close_on_exec=).with(true).and_return(:nil)
      obj_w = mock("writer_io")
      obj_w.should_receive(:close_on_exec=).with(true).and_return(:nil)
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.send(:close_on_exec=, true).should be_true
    end

    it "raises IOError when the reader delegate raises it" do
      obj_r = mock("reader_io")
      obj_r.should_receive(:close_on_exec=).with(true).and_raise(IOError.new('closed stream'))
      obj_w = mock("writer_io")
      obj_w.should_not_receive(:close_on_exec=)
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      -> { io.send(:close_on_exec=, true) }.should raise_error(IOError, 'closed stream')
    end

    it "raises IOError when the writer delegate raises it" do
      obj_r = mock("reader_io")
      obj_r.should_receive(:close_on_exec=).with(true).and_return(nil)
      obj_w = mock("writer_io")
      obj_w.should_receive(:close_on_exec=).with(true).and_raise(IOError.new('closed stream'))
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      -> { io.send(:close_on_exec=, true) }.should raise_error(IOError, 'closed stream')
    end

    it "delegates to the reader delegate when the write stream is closed" do
      obj_r = mock("reader_io")
      obj_r.should_receive(:close_on_exec=).with(true).and_return(true)
      obj_w = mock("writer_io")
      obj_w.should_not_receive(:close_on_exec=)
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.close_write
      io.send(:close_on_exec=, true).should be_true
    end

    it "delegates to the writer delegate when the read stream is closed" do
      obj_r = mock("reader_io")
      obj_r.should_not_receive(:close_on_exec=)
      obj_w = mock("writer_io")
      obj_w.should_receive(:close_on_exec=).with(true).and_return(true)
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.close_read
      io.send(:close_on_exec=, true).should be_true
    end

    it "raises IOError when both streams are closed" do
      obj_r = mock("reader_io")
      obj_r.should_not_receive(:close_on_exec=)
      obj_w = mock("writer_io")
      obj_w.should_not_receive(:close_on_exec=)
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.close_read
      io.close_write
      -> { io.send(:close_on_exec=, true) }.should raise_error(IOError, 'closed stream')
    end

    it "raises IOError if the stream is closed" do
      obj_r = mock("reader_io")
      obj_r.should_not_receive(:close_on_exec=)
      obj_w = mock("writer_io")
      obj_w.should_not_receive(:close_on_exec=)
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.close
      -> { io.send(:close_on_exec=, true) }.should raise_error(IOError, 'closed stream')
    end
  end
end

describe "IO::LikeHelpers::DuplexedIO#close_on_exec?" do
  describe "when not duplexed" do
    it "delegates to its delegate" do
      obj = mock("io")
      obj.should_receive(:close_on_exec?).and_return(true)
      io = IO::LikeHelpers::DuplexedIO.new(obj, autoclose: false)
      io.close_on_exec?.should be_true
    end

    it "raises IOError when the delegate is closed" do
      obj = mock("io")
      obj.should_receive(:close_on_exec?).and_raise(IOError.new('closed stream'))
      io = IO::LikeHelpers::DuplexedIO.new(obj, autoclose: false)
      -> { io.close_on_exec? }.should raise_error(IOError, 'closed stream')
    end
  end

  describe "when duplexed" do
    it "delegates to the reader delegate when not closed" do
      obj_r = mock("reader_io")
      obj_r.should_receive(:close_on_exec?).and_return(:result)
      obj_w = mock("writer_io")
      obj_w.should_not_receive(:close_on_exec?)
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.close_on_exec?.should == :result
    end

    it "delegates to the reader delegate when the write stream is closed" do
      obj_r = mock("reader_io")
      obj_r.should_receive(:close_on_exec?).and_return(:result)
      obj_w = mock("writer_io")
      obj_w.should_not_receive(:close_on_exec?)
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.close_write
      io.close_on_exec?.should == :result
    end

    it "delegates to the writer delegate when the read stream is closed" do
      obj_r = mock("reader_io")
      obj_r.should_not_receive(:close_on_exec?)
      obj_w = mock("writer_io")
      obj_w.should_receive(:close_on_exec?).and_return(:result)
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.close_read
      io.close_on_exec?.should == :result
    end

    it "raises IOError when both streams are closed" do
      obj_r = mock("reader_io")
      obj_r.should_not_receive(:close_on_exec?)
      obj_w = mock("writer_io")
      obj_w.should_not_receive(:close_on_exec?)
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.close_read
      io.close_write
      -> { io.close_on_exec? }.should raise_error(IOError, 'closed stream')
    end

    it "raises IOError if the stream is closed" do
      obj_r = mock("reader_io")
      obj_r.should_not_receive(:close_on_exec?)
      obj_w = mock("writer_io")
      obj_w.should_not_receive(:close_on_exec?)
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.close
      -> { io.close_on_exec? }.should raise_error(IOError, 'closed stream')
    end
  end
end

# vim: ts=2 sw=2 et
