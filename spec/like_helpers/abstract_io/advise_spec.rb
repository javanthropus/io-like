# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::AbstractIO#advise" do
  it "returns nil" do
    io = IO::LikeHelpers::AbstractIO.new
    io.advise(:foo, 0, 1).should be_nil
  end
end

# vim: ts=2 sw=2 et
