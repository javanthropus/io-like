# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'
require_relative '../../../rubyspec/core/io/fixtures/classes'

describe "IO::LikeHelpers::DelegatedIO#nonblock=" do
  it "delegates to its delegate" do
    obj = mock("io")
    obj.should_receive(:nonblock=).with(true).and_return(true)
    io = IO::LikeHelpers::DelegatedIO.new(obj)
    io.send(:nonblock=, true).should == true
  end
end

describe "IO::LikeHelpers::DelegatedIO#nonblock?" do
  it "delegates to its delegate" do
    obj = mock("io")
    obj.should_receive(:nonblock?).and_return(true)
    io = IO::LikeHelpers::DelegatedIO.new(obj)
    io.nonblock?.should == true
  end
end

# vim: ts=2 sw=2 et
