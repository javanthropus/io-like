# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DuplexedIO#inspect" do
  it "emits a string representation of the stream" do
    obj1 = mock("io1")
    obj1.should_receive(:inspect).and_return("delegate_obj1")
    obj2 = mock("io2")
    obj2.should_receive(:inspect).and_return("delegate_obj2")
    io = IO::LikeHelpers::DuplexedIO.new(obj1, obj2)
    io.inspect.should == "<IO::LikeHelpers::DuplexedIO:delegate_obj1, delegate_obj2>"
  end

  it "emits a string representation of the stream when not duplexed" do
    obj = mock("io")
    obj.should_receive(:inspect).and_return("delegate_obj")
    io = IO::LikeHelpers::DuplexedIO.new(obj)
    io.inspect.should == "<IO::LikeHelpers::DuplexedIO:delegate_obj>"
  end
end

# vim: ts=2 sw=2 et
