# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DuplexedIO#nread" do
  it "delegates to its delegate" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:nread).and_return(0)
    io = IO::LikeHelpers::DuplexedIO.new(obj)
    io.nread.should == 0
  end

  it "raises IOError when its delegate raises it" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:nread).and_raise(IOError.new('closed stream'))
    io = IO::LikeHelpers::DuplexedIO.new(obj)
    -> { io.nread }.should raise_error(IOError, 'closed stream')
  end

  it "raises IOError when the delegate is not readable" do
    obj = mock("reader_io")
    obj.should_receive(:readable?).and_return(false)
    io = IO::LikeHelpers::DuplexedIO.new(obj)
    -> { io.nread }.should raise_error(IOError, 'not opened for reading')
  end

  it "delegates to the reader delegate when not closed" do
    obj_r = mock("reader_io")
    obj_r.should_receive(:readable?).and_return(true)
    obj_r.should_receive(:nread).and_return(0)
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w)
    io.nread.should == 0
  end

  it "delegates to the reader delegate when the write stream is closed" do
    obj_r = mock("reader_io")
    obj_r.should_receive(:readable?).and_return(true)
    obj_r.should_receive(:nread).and_return(0)
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close_write
    io.nread.should == 0
  end

  it "raises IOError when the read stream is closed" do
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close_read
    -> { io.nread }.should raise_error(IOError, 'not opened for reading')
  end

  it "raises IOError if the stream is closed" do
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close
    -> { io.nread }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
