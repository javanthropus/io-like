# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'
require_relative '../../../rubyspec/core/io/fixtures/classes'

describe "IO::LikeHelpers::DelegatedIO#advise" do
  it "delegates to its delegate" do
    obj = mock("io")
    obj.should_receive(:advise).and_return(:result)
    io = IO::LikeHelpers::DelegatedIO.new(obj)
    io.advise(:foo).should == :result
  end
end

# vim: ts=2 sw=2 et
