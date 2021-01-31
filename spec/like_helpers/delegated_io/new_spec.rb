# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DelegatedIO.new" do
  it "raises ArgumentError if the delegate is nil" do
    -> { IO::LikeHelpers::DelegatedIO.new(nil) }.should raise_error(ArgumentError)
  end

  it "enables autoclose by default" do
    obj = mock("io")
    io = IO::LikeHelpers::DelegatedIO.new(obj)
    io.autoclose?.should be_true
  end

  it "allows autoclose to be set" do
    obj = mock("io")
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.autoclose?.should be_false
  end
end
