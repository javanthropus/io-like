# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'
require_relative '../../../rubyspec/core/io/fixtures/classes'

describe "IO::LikeHelpers::DelegatedIO#close_on_exec=" do
  it "delegates to its delegate" do
    obj = mock("io")
    obj.should_receive(:close_on_exec=).and_return(:nil)
    io = IO::LikeHelpers::DelegatedIO.new(obj)
    io.send(:close_on_exec=, true).should be_nil
  end
end

describe "IO::LikeHelpers::DelegatedIO#close_on_exec?" do
  it "delegates to its delegate" do
    obj = mock("io")
    obj.should_receive(:close_on_exec?).and_return(true)
    io = IO::LikeHelpers::DelegatedIO.new(obj)
    io.close_on_exec?.should == true
  end
end

# vim: ts=2 sw=2 et
