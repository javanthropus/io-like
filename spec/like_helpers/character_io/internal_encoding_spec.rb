# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

require 'io/like_helpers/character_io'

describe "IO::LikeHelpers::CharacterIO#internal_encoding" do
  it "returns the internal encoding when explicitly set" do
    obj = mock("io")
    io = IO::LikeHelpers::CharacterIO.new(
      obj,
      external_encoding: Encoding::UTF_8,
      internal_encoding: Encoding::UTF_16LE
    )
    io.internal_encoding.should == Encoding::UTF_16LE
  end

  it "returns nil if the internal encoding is not set" do
    obj = mock("io")
    io = IO::LikeHelpers::CharacterIO.new(
      obj,
      external_encoding: Encoding::UTF_8
    )
    io.internal_encoding.should == nil
  end
end

# vim: ts=2 sw=2 et
