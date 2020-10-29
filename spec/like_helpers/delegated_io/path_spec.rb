# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'
require_relative '../../../rubyspec/core/io/fixtures/classes'

describe "IO::LikeHelpers::DelegatedIO#path" do
  it "delegates to its delegate" do
    obj = mock("io")
    obj.should_receive(:path).and_return("foo")
    io = IO::LikeHelpers::DelegatedIO.new(obj)
    io.path.should == "foo"
  end
end

# vim: ts=2 sw=2 et
