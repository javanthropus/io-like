# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DelegatedIO#close_on_exec=" do
  it "delegates to its delegate" do
    obj = mock("io")
    obj.should_receive(:close_on_exec=).with(true).and_return(:nil)
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.send(:close_on_exec=, true).should be_true
  end

  it "raises IOError when its delegate raises it" do
    obj = mock("io")
    obj.should_receive(:close_on_exec=).with(true).and_raise(IOError.new('closed stream'))
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    -> { io.send(:close_on_exec=, true) }.should raise_error(IOError, 'closed stream')
  end

  it "raises IOError if the stream is closed" do
    obj = mock("io")
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.close
    -> { io.send(:close_on_exec=, false) }.should raise_error(IOError, 'closed stream')
  end
end

describe "IO::LikeHelpers::DelegatedIO#close_on_exec?" do
  it "delegates to its delegate" do
    obj = mock("io")
    obj.should_receive(:close_on_exec?).and_return(true)
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.close_on_exec?.should be_true
  end

  it "raises IOError when its delegate raises it" do
    obj = mock("io")
    obj.should_receive(:close_on_exec?).and_raise(IOError.new('closed stream'))
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    -> { io.close_on_exec? }.should raise_error(IOError, 'closed stream')
  end

  it "raises IOError if the stream is closed" do
    obj = mock("io")
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.close
    -> { io.close_on_exec? }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
