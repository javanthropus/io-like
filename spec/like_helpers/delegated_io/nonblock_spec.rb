# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DelegatedIO#nonblock=" do
  it "delegates to its delegate" do
    obj = mock("io")
    obj.should_receive(:nonblock=).with(true).and_return(true)
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.send(:nonblock=, true).should be_true
  end

  it "raises IOError when its delegate raises it" do
    obj = mock("io")
    obj.should_receive(:nonblock=).with(true).and_raise(IOError.new('closed stream'))
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    -> { io.send(:nonblock=, true) }.should raise_error(IOError, 'closed stream')
  end

  it "raises IOError if the stream is closed" do
    obj = mock("io")
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.close
    -> { io.send(:nonblock=, true) }.should raise_error(IOError, 'closed stream')
  end
end

describe "IO::LikeHelpers::DelegatedIO#nonblock?" do
  it "delegates to its delegate" do
    obj = mock("io")
    obj.should_receive(:nonblock?).and_return(true)
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.nonblock?.should be_true
  end

  it "raises IOError when its delegate is closed" do
    obj = mock("io")
    obj.should_receive(:nonblock?).and_raise(IOError.new('closed stream'))
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    -> { io.nonblock? }.should raise_error(IOError, 'closed stream')
  end

  it "raises IOError if the stream is closed" do
    obj = mock("io")
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.close
    -> { io.nonblock? }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
