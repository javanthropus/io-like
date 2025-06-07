# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::AbstractIO#writable?" do
  it "returns false" do
    io = IO::LikeHelpers::AbstractIO.new
    io.writable?.should be_false
  end
end

# vim: ts=2 sw=2 et
