# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::BufferedIO#fdatasync" do
  it "delegates to its delegate" do
    obj = mock("io")
    obj.should_receive(:fdatasync).and_return(nil)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.fdatasync.should be_nil
  end

  it "flushes the write buffer" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:write).with(buffer).and_return(3)
    obj.should_receive(:fdatasync).and_return(0)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.write(buffer)
    io.fdatasync.should == 0
  end

  it "returns a Symbol if delegate.write does so when there is buffered data" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:write).with(buffer).and_return(:wait_readable)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.write(buffer)
    io.fdatasync.should == :wait_readable
  end

  it "raises IOError if the stream is closed" do
    obj = mock("io")
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
    io.close
    -> { io.fdatasync }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
