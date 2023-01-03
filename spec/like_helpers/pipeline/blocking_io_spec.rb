# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::Pipeline#blocking_io" do
  it "returns a kind of BlockingIO" do
    obj = mock("io")
    io = IO::LikeHelpers::Pipeline.new(obj, autoclose: false)
    io.blocking_io.should be_kind_of(IO::LikeHelpers::BlockingIO)
  end
end
