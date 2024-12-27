# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DelegatedIO#read" do
  it "delegates to its delegate" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).with(1, buffer: buffer).and_return(:result)
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.read(1, buffer: buffer).should == :result
  end

  it "raises IOError when its delegate raises it" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).with(1, buffer: buffer).and_raise(IOError.new('closed stream'))
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    -> { io.read(1, buffer: buffer) }.should raise_error(IOError, 'closed stream')
  end

  it "raises IOError if its delegate is not readable" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:readable?).and_return(false)
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    -> { io.read(1, buffer: buffer) }.should raise_error(IOError, 'not opened for reading')
  end

  it "raises IOError if the stream is closed" do
    buffer = 'foo'.b
    obj = mock("io")
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.close
    -> { io.read(1, buffer: buffer) }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
