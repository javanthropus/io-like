# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

require 'io/like_helpers/character_io'

describe "IO::LikeHelpers::CharacterIO#buffer_empty?" do
  before :each do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    @io = IO::LikeHelpers::CharacterIO.new(
      obj,
    )
    @io.set_encoding(Encoding::UTF_8, Encoding::UTF_16LE)
  end

  it "returns true when the internal buffer is empty" do
    @io.buffer_empty?.should be_true
  end

  it "returns false when the internal buffer is not empty" do
    @io.unread("a".encode(Encoding::UTF_16LE))
    @io.buffer_empty?.should be_false
  end
end

# vim: ts=2 sw=2 et
