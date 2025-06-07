# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::BufferedIO#skip" do
  it "returns 0 if the stream is not in read mode" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:readable?).and_return(true)
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
    io.write(buffer).should == buffer.size
    io.skip(3).should == 0
  end

  it "returns the number of bytes skipped in the read buffer" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).and_return(3)
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false, buffer_size: 100)
    io.read(1)
    io.skip(2).should == 2
  end

  it "skips all bytes in the read buffer when length not provided" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).and_return(3)
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false, buffer_size: 100)
    io.read(1)
    io.skip.should == 2
  end

  it "returns fewer bytes than requested if not enough bytes are available" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).and_return(3)
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false, buffer_size: 100)
    io.read(1)
    io.skip(3).should == 2
  end

  it "raises ArgumentError if length is invalid" do
    obj = mock("io")
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
    -> { io.skip(-1) }.should raise_error(ArgumentError)
  end

  it "raises IOError if its delegate is not readable" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(false)
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
    -> { io.skip(1) }.should raise_error(IOError, 'not opened for reading')
  end

  it "raises IOError if the stream is closed" do
    obj = mock("io")
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
    io.close
    -> { io.skip(1) }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
