# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

require 'io/like_helpers/character_io'

describe "IO::LikeHelpers::CharacterIO#external_encoding" do
  it "returns the external encoding when explicitly set" do
    obj = mock("io")
    io = IO::LikeHelpers::CharacterIO.new(
      obj,
      external_encoding: Encoding::UTF_8,
      internal_encoding: Encoding::UTF_16LE
    )
    io.external_encoding.should == Encoding::UTF_8
  end

  it "returns nil if the external encoding is not set and the stream is writable" do
    obj = mock("io")
    io = IO::LikeHelpers::CharacterIO.new(obj)
    io.external_encoding.should == nil
  end
end

# vim: ts=2 sw=2 et
