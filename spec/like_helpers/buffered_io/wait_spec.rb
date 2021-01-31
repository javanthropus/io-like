# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::BufferedIO#wait" do
  it "delegates to its delegate when the internal read buffer is empty" do
    obj = mock("io")
    obj.should_receive(:wait).with(IO::READABLE, nil).and_return(:result)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.wait(IO::READABLE).should == :result
  end

  it "delegates to its delegate when the events to wait for do not imply readability" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).and_return(3)
    obj.should_receive(:wait).with(IO::WRITABLE, nil).and_return(:result)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.read(1)
    io.wait(IO::WRITABLE).should == :result
  end

  it "returns true when the internal read buffer is not empty and the events to wait for imply readability" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).and_return(3)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.read(1)
    io.wait(IO::READABLE).should be_true
    io.wait(IO::PRIORITY).should be_true
  end

  it "raises IOError if the stream is closed" do
    obj = mock("io")
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
    io.close
    -> { io.wait(IO::READABLE) }.should raise_error(IOError, 'closed stream')
  end
end
