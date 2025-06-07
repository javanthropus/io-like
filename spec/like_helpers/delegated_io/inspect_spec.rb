# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DelegatedIO#inspect" do
  it "emits a string representation of the stream" do
    obj = mock("io")
    obj.should_receive(:inspect).and_return("delegate_obj")
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.inspect.should == "<IO::LikeHelpers::DelegatedIO:delegate_obj>"
  end

  it "emits a string representation of the stream when the stream is closed" do
    obj = mock("io")
    obj.should_receive(:inspect).and_return("delegate_obj")
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.close
    io.inspect.should == "<IO::LikeHelpers::DelegatedIO:delegate_obj (closed)>"
  end
end

# vim: ts=2 sw=2 et
