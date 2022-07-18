# -*- encoding: utf-8 -*-
require_relative '../../spec_helper'

describe "IO::Like#nread" do
  it "delegates to its delegate" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:nread).and_return(0)
    io = IO::Like.new(obj)
    io.nread.should == 0
  end

  it "raises IOError if its delegate is not readable" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(false)
    io = IO::Like.new(obj)
    -> { io.nread }.should raise_error(IOError, 'not opened for reading')
  end

  it "raises IOError if the stream is closed" do
    obj = mock("io")
    obj.should_receive(:writable?).and_return(false)
    io = IO::Like.new(obj, autoclose: false)
    io.close
    -> { io.nread }.should raise_error(IOError, 'closed stream')
  end

  it "blocks even when the delegate does not" do
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:readable?).and_return(true).exactly(2)
    obj.should_receive(:nread).and_return(:wait_writable, :wait_readable, 0)
    obj.should_receive(:wait).and_return(true, true)
    io = IO::Like.new(obj)
    io.nread.should == 0
  end
end

# vim: ts=2 sw=2 et
