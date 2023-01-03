# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::BufferedIO#nread" do
  it "returns 0 when in write mode" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:readable?).and_return(true)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.write(buffer)
    io.nread.should == 0
  end

  it "returns the number of bytes in the internal read buffer when in read mode with a non-empty read buffer" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).and_return(3)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.read(1)
    io.nread.should == 2
  end

  it "raises IOError if its delegate is not readable" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(false)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    -> { io.nread }.should raise_error(IOError, 'not opened for reading')
  end

  it "raises IOError if stream is closed" do
    obj = mock("io")
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
    io.close
    -> { io.nread }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
