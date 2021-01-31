# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DelegatedIO#wait" do
  it "delegates to its delegate" do
    obj = mock("io")
    obj.should_receive(:wait).with(:events, :timeout).and_return(true)
    io = IO::LikeHelpers::DelegatedIO.new(obj)
    io.wait(:events, :timeout).should be_true
  end

  it "raises IOError if the stream is closed" do
    obj = mock("io")
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.close
    -> { io.wait(:events, :timeout) }.should raise_error(IOError, 'closed stream')
  end
end
