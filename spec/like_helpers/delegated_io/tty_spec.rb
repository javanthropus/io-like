# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DelegatedIO#tty?" do
  it "delegates to its delegate" do
    obj = mock("io")
    obj.should_receive(:tty?).and_return(:result)
    io = IO::LikeHelpers::DelegatedIO.new(obj)
    io.tty?.should == :result
  end

  it "raises IOError if the stream is closed" do
    obj = mock("io")
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.close
    -> { io.tty? }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
