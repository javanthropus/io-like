# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::Pipeline#buffered_io" do
  it "returns a kind of BufferedIO" do
    obj = mock("io")
    io = IO::LikeHelpers::Pipeline.new(obj, autoclose: false)
    io.buffered_io.should be_kind_of(IO::LikeHelpers::BufferedIO)
  end
end

# vim: ts=2 sw=2 et
