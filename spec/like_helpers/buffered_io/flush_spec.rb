# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::BufferedIO#flush" do
  it "flushes the write buffer" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:write).with(buffer).and_return(1)
    obj.should_receive(:write).with(buffer[1, 2]).and_return(buffer.size - 1)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.write(buffer)
    io.flush.should be_nil
  end

  it "returns a Symbol if delegate.write does so when there is buffered data" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:write).with(buffer).and_return(:wait_readable)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.write(buffer)
    io.flush.should == :wait_readable
  end

  it "does nothing if there is no buffered data" do
    obj = mock("io")
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.flush.should be_nil
  end

  it "raises IOError if the stream is closed" do
    obj = mock("io")
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
    io.close
    -> { io.flush }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
