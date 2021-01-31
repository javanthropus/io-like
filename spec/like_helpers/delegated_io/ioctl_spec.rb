# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DelegatedIO#ioctl" do
  it "delegates to its delegate" do
    obj = mock("io")
    obj.should_receive(:ioctl).with(0, 1).and_return(nil)
    io = IO::LikeHelpers::DelegatedIO.new(obj)
    io.ioctl(0, 1).should be_nil
  end

  it "raises IOError if the stream is closed" do
    obj = mock("io")
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.close
    -> { io.ioctl(0, 1) }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
