# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'
require_relative '../../../rubyspec/core/io/fixtures/classes'

describe "IO::LikeHelpers::DelegatedIO#tty?" do
  it "delegates to its delegate" do
    obj = mock("io")
    obj.should_receive(:tty?).and_return(false)
    io = IO::LikeHelpers::DelegatedIO.new(obj)
    io.tty?.should == false
  end
end

# vim: ts=2 sw=2 et
