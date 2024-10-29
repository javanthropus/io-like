# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

require 'io/like_helpers/character_io'

describe "IO::LikeHelpers::CharacterIO#readable?" do
  it "returns the true if the delegate is readable" do
    obj = mock("io")
    obj.should_receive(:readable?).once.and_return(true)
    io = IO::LikeHelpers::CharacterIO.new(
      obj,
      external_encoding: Encoding::UTF_8,
      internal_encoding: Encoding::UTF_16LE
    )
    io.readable?.should be_true
    # Ensures the delegate is only asked once.
    io.readable?.should be_true
  end

  it "returns the false if the delegate is not readable" do
    obj = mock("io")
    obj.should_receive(:readable?).once.and_return(false)
    io = IO::LikeHelpers::CharacterIO.new(
      obj,
      external_encoding: Encoding::UTF_8,
      internal_encoding: Encoding::UTF_16LE
    )
    io.readable?.should be_false
    # Ensures the delegate is only asked once.
    io.readable?.should be_false
  end
end

# vim: ts=2 sw=2 et
