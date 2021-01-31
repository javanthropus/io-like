# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'
require_relative '../../../rubyspec/core/io/fixtures/classes'

describe "IO::LikeHelpers::DuplexedIO#to_i" do
  it "delegates to its delegate" do
    obj = mock("io")
    # NOTE:
    # #to_i is an alias for #fileno
    obj.should_receive(:fileno).and_return(nil)
    io = IO::LikeHelpers::DuplexedIO.new(obj)
    io.to_i.should be_nil
  end

  it "raises IOError when its delegate raises it" do
    obj = mock("io")
    # NOTE:
    # #to_i is an alias for #fileno
    obj.should_receive(:fileno).and_raise(IOError.new('closed stream'))
    io = IO::LikeHelpers::DuplexedIO.new(obj)
    -> { io.to_i }.should raise_error(IOError, 'closed stream')
  end

  it "delegates to the reader delegate when not closed" do
    obj_r = mock("reader_io")
    # NOTE:
    # #to_i is an alias for #fileno
    obj_r.should_receive(:fileno).and_return(nil)
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w)
    io.to_i.should be_nil
  end

  it "delegates to the reader delegate when the write stream is closed" do
    obj_r = mock("reader_io")
    # NOTE:
    # #to_i is an alias for #fileno
    obj_r.should_receive(:fileno).and_return(nil)
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close_write
    io.to_i.should be_nil
  end

  it "delegates to the writer delegate when the read stream is closed" do
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    # NOTE:
    # #to_i is an alias for #fileno
    obj_w.should_receive(:fileno).and_return(nil)
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close_read
    io.to_i.should be_nil
  end

  it "raises IOError when both streams are closed" do
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close_read
    io.close_write
    -> { io.to_i }.should raise_error(IOError, 'closed stream')
  end

  it "raises IOError if the stream is closed" do
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close
    -> { io.to_i }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
