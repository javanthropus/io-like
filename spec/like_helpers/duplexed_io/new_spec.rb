# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DuplexedIO.new" do
  it "raises ArgumentError if the delegate_r is nil" do
    -> { IO::LikeHelpers::DuplexedIO.new(nil) }.should raise_error(ArgumentError)
  end

  it "raises ArgumentError if the delegate_w is nil" do
    -> { IO::LikeHelpers::DuplexedIO.new(:dummy, nil) }.should raise_error(ArgumentError)
  end

  it "enables autoclose by default" do
    obj = mock("io")
    io = IO::LikeHelpers::DuplexedIO.new(obj)
    io.autoclose?.should be_true
  end

  it "allows autoclose to be set" do
    obj = mock("io")
    io = IO::LikeHelpers::DuplexedIO.new(obj, autoclose: false)
    io.autoclose?.should be_false
  end
end
