# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DelegatedIO#wait" do
  it "delegates to its delegate" do
    obj = mock("io")
    obj.should_receive(:wait).with(:events, :timeout).and_return(true)
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.wait(:events, :timeout).should be_true
  end

  it "raises IOError when its delegate raises it" do
    obj = mock("io")
    obj.should_receive(:wait).with(:events, :timeout).and_raise(IOError.new('closed stream'))
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    -> { io.wait(:events, :timeout) }.should raise_error(IOError, 'closed stream')
  end

  it "raises IOError if the stream is closed" do
    obj = mock("io")
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.close
    -> { io.wait(:events, :timeout) }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
