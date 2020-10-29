# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'
require_relative '../../../rubyspec/core/io/fixtures/classes'

describe "IO::LikeHelpers::DelegatedIO#pid" do
  it "delegates to its delegate" do
    obj = mock("io")
    obj.should_receive(:pid).and_return(0)
    io = IO::LikeHelpers::DelegatedIO.new(obj)
    io.pid.should == 0
  end
end

# vim: ts=2 sw=2 et
