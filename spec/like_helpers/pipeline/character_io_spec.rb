# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::Pipeline#character_io" do
  it "returns a kind of CharacterIO" do
    obj = mock("io")
    io = IO::LikeHelpers::Pipeline.new(obj, autoclose: false)
    io.character_io.should be_kind_of(IO::LikeHelpers::CharacterIO)
  end
end

# vim: ts=2 sw=2 et
