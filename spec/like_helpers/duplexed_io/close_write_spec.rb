# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DuplexedIO#close_write" do
  it "delegates to its delegate when #autoclose? is true" do
    obj = mock("io")
    obj.should_receive(:close).and_return(nil)
    io = IO::LikeHelpers::DuplexedIO.new(obj)
    io.close_write.should be_nil
  end

  it "short circuits after the first call" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:close).and_return(nil)
    io = IO::LikeHelpers::DuplexedIO.new(obj)
    io.close_write.should be_nil
    io.close_write.should be_nil
  end

  it "delegates only to the writer delegate when #autoclose? is true" do
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    obj_w.should_receive(:close).and_return(nil)
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w)
    io.close_write.should be_nil
  end

  it "does not delegate to its delegate when #autoclose? is false" do
    obj = mock("io")
    io = IO::LikeHelpers::DuplexedIO.new(obj, autoclose: false)
    io.close_write.should be_nil
  end

  it "returns a Symbol if its delegate does so" do
    obj = mock("io")
    obj.should_receive(:close).and_return(:wait_writable)
    io = IO::LikeHelpers::DuplexedIO.new(obj)
    io.close_write.should == :wait_writable
  end
end

# vim: ts=2 sw=2 et
