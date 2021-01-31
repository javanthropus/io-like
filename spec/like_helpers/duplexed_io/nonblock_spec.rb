# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DuplexedIO#nonblock=" do
  it "delegates to its delegate" do
    obj = mock("io")
    obj.should_receive(:nonblock=).with(true).and_return(true)
    io = IO::LikeHelpers::DuplexedIO.new(obj)
    io.send(:nonblock=, true).should be_true
  end

  it "raises IOError when its delegate raises it" do
    obj = mock("io")
    obj.should_receive(:nonblock=).with(true).and_raise(IOError.new('closed stream'))
    io = IO::LikeHelpers::DuplexedIO.new(obj)
    -> { io.send(:nonblock=, true) }.should raise_error(IOError, 'closed stream')
  end

  it "delegates to both delegates" do
    obj_r = mock("reader_io")
    obj_r.should_receive(:nonblock=).with(true).and_return(true)
    obj_w = mock("writer_io")
    obj_w.should_receive(:nonblock=).with(true).and_return(true)
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w)
    io.send(:nonblock=, true).should be_true
  end

  it "raises IOError when the reader delegate raises it" do
    obj_r = mock("reader_io")
    obj_r.should_receive(:nonblock=).with(true).and_raise(IOError.new('closed stream'))
    obj_w = mock("writer_io")
    obj_w.should_receive(:nonblock=).with(true).and_return(true)
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w)
    -> { io.send(:nonblock=, true) }.should raise_error(IOError, 'closed stream')
  end

  it "raises IOError when the writer delegate raises it" do
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    obj_w.should_receive(:nonblock=).with(true).and_raise(IOError.new('closed stream'))
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w)
    -> { io.send(:nonblock=, true) }.should raise_error(IOError, 'closed stream')
  end

  it "delegates to the reader delegate when the write stream is closed" do
    obj_r = mock("reader_io")
    obj_r.should_receive(:nonblock=).with(true).and_return(true)
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close_write
    io.send(:nonblock=, true).should be_true
  end

  it "delegates to the writer delegate when the read stream is closed" do
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    obj_w.should_receive(:nonblock=).with(true).and_return(true)
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close_read
    io.send(:nonblock=, true).should be_true
  end

  it "raises IOError when both streams are closed" do
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close_read
    io.close_write
    -> { io.send(:nonblock=, true) }.should raise_error(IOError, 'closed stream')
  end

  it "raises IOError if the stream is closed" do
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close
    -> { io.send(:nonblock=, true) }.should raise_error(IOError, 'closed stream')
  end
end

describe "IO::LikeHelpers::DuplexedIO#nonblock?" do
  it "delegates to its delegate" do
    obj = mock("io")
    obj.should_receive(:nonblock?).and_return(true)
    io = IO::LikeHelpers::DuplexedIO.new(obj)
    io.nonblock?.should be_true
  end

  it "raises IOError when the delegate is closed" do
    obj = mock("io")
    obj.should_receive(:nonblock?).and_raise(IOError.new('closed stream'))
    io = IO::LikeHelpers::DuplexedIO.new(obj)
    -> { io.nonblock? }.should raise_error(IOError, 'closed stream')
  end

  it "delegates to the reader delegate when not closed" do
    obj_r = mock("reader_io")
    obj_r.should_receive(:nonblock?).and_return(true)
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close_write
    io.nonblock?.should be_true
  end

  it "delegates to the reader delegate when the write stream is closed" do
    obj_r = mock("reader_io")
    obj_r.should_receive(:nonblock?).and_return(true)
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close_write
    io.nonblock?.should be_true
  end

  it "delegates to the writer delegate when the read stream is closed" do
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    obj_w.should_receive(:nonblock?).and_return(true)
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close_read
    io.nonblock?.should be_true
  end

  it "raises IOError when both streams are closed" do
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close_read
    io.close_write
    -> { io.nonblock? }.should raise_error(IOError, 'closed stream')
  end

  it "raises IOError if the stream is closed" do
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close
    -> { io.nonblock? }.should raise_error(IOError, 'closed stream')
  end
end

describe "IO::LikeHelpers::DuplexedIO#nonblock" do
  it "enables nonblocking mode by default for the duration of the call and yields self to the block" do
    obj = mock("io")
    obj.should_receive(:nonblock?).and_return(false)
    obj.should_receive(:nonblock=).with(true).and_return(true)
    obj.should_receive(:nonblock=).with(false).and_return(false)
    io = IO::LikeHelpers::DuplexedIO.new(obj)
    io.nonblock do |self_io|
      self_io.should == io
    end
  end

  it "enables nonblocking mode when directed for the duration of the call and yields self to the block" do
    obj = mock("io")
    obj.should_receive(:nonblock?).and_return(false)
    obj.should_receive(:nonblock=).with(true).and_return(true)
    obj.should_receive(:nonblock=).with(false).and_return(false)
    io = IO::LikeHelpers::DuplexedIO.new(obj)
    io.nonblock(true) do |self_io|
      self_io.should == io
    end
  end

  it "disables nonblocking mode when directed for the duration of the call and yields self to the block" do
    obj = mock("io")
    obj.should_receive(:nonblock?).and_return(true)
    obj.should_receive(:nonblock=).with(false).and_return(false)
    obj.should_receive(:nonblock=).with(true).and_return(true)
    io = IO::LikeHelpers::DuplexedIO.new(obj)
    io.nonblock(false) do |self_io|
      self_io.should == io
    end
  end

  it "enables nonblocking mode by default on both delegates for the duration of the call and yields self to the block" do
    obj_r = mock("reader_io")
    obj_r.should_receive(:nonblock?).and_return(false)
    obj_r.should_receive(:nonblock=).with(true).and_return(true)
    obj_r.should_receive(:nonblock=).with(false).and_return(false)
    obj_w = mock("writer_io")
    obj_w.should_receive(:nonblock=).with(true).and_return(true)
    obj_w.should_receive(:nonblock=).with(false).and_return(false)
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w)
    io.nonblock do |self_io|
      self_io.should == io
    end
  end

  it "enables nonblocking mode when directed on both delegates for the duration of the call and yields self to the block" do
    obj_r = mock("reader_io")
    obj_r.should_receive(:nonblock?).and_return(false)
    obj_r.should_receive(:nonblock=).with(true).and_return(true)
    obj_r.should_receive(:nonblock=).with(false).and_return(false)
    obj_w = mock("writer_io")
    obj_w.should_receive(:nonblock=).with(true).and_return(true)
    obj_w.should_receive(:nonblock=).with(false).and_return(false)
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w)
    io.nonblock(true) do |self_io|
      self_io.should == io
    end
  end

  it "disables nonblocking mode when directed on both delegates for the duration of the call and yields self to the block" do
    obj_r = mock("reader_io")
    obj_r.should_receive(:nonblock?).and_return(true)
    obj_r.should_receive(:nonblock=).with(false).and_return(false)
    obj_r.should_receive(:nonblock=).with(true).and_return(true)
    obj_w = mock("writer_io")
    obj_w.should_receive(:nonblock=).with(false).and_return(false)
    obj_w.should_receive(:nonblock=).with(true).and_return(true)
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w)
    io.nonblock(false) do |self_io|
      self_io.should == io
    end
  end

  it "enables nonblocking mode on the reader delegate when the write stream is closed" do
    obj_r = mock("reader_io")
    obj_r.should_receive(:nonblock?).and_return(false)
    obj_r.should_receive(:nonblock=).with(true).and_return(true)
    obj_r.should_receive(:nonblock=).with(false).and_return(false)
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close_write
    io.nonblock do |self_io|
      self_io.should == io
    end
  end

  it "enables nonblocking mode on the writer delegate when the read stream is closed" do
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    obj_w.should_receive(:nonblock?).and_return(false)
    obj_w.should_receive(:nonblock=).with(true).and_return(true)
    obj_w.should_receive(:nonblock=).with(false).and_return(false)
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close_read
    io.nonblock do |self_io|
      self_io.should == io
    end
  end

  it "raises IOError when both streams are closed" do
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close_read
    io.close_write
    -> { io.nonblock(true) { |self_io| } }.should raise_error(IOError, 'closed stream')
  end

  it "raises IOError if the stream is closed" do
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close
    -> { io.nonblock(true) { |self_io| } }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
