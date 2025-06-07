# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::AbstractIO#readable?" do
  it "returns false" do
    io = IO::LikeHelpers::AbstractIO.new
    io.readable?.should be_false
  end
end

# vim: ts=2 sw=2 et
