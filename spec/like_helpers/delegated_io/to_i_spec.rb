# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'
require_relative '../../../rubyspec/core/io/fixtures/classes'

describe "IO::LikeHelpers::DelegatedIO#to_i" do
  it "delegates to its delegate" do
    obj = mock("io")
    # NOTE:
    # #to_i is an alias for #fileno
    obj.should_receive(:fileno).and_return(nil)
    io = IO::LikeHelpers::DelegatedIO.new(obj)
    io.to_i.should be_nil
  end
end

# vim: ts=2 sw=2 et
