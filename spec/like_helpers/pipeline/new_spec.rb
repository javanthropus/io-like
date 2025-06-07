# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::Pipeline.new" do
  it "raises ArgumentError if the delegate is nil" do
    -> { IO::LikeHelpers::Pipeline.new(nil) }.should raise_error(ArgumentError)
  end

  it "enables autoclose by default" do
    obj = mock("io")
    obj.should_receive(:close).and_return(nil)
    io = IO::LikeHelpers::Pipeline.new(obj)
    io.close
  end

  it "allows autoclose to be set" do
    obj = mock("io")
    obj.should_not_receive(:close)
    io = IO::LikeHelpers::Pipeline.new(obj, autoclose: false)
    io.close
  end
end

# vim: ts=2 sw=2 et
