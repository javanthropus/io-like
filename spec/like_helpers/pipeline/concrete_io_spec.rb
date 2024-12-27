# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::Pipeline#concrete_io" do
  it "returns the original delegate" do
    obj = mock("io")
    io = IO::LikeHelpers::Pipeline.new(obj, autoclose: false)
    io.concrete_io.should equal(obj)
  end
end

# vim: ts=2 sw=2 et
