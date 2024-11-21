# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

require 'io/like_helpers/character_io'

describe "IO::LikeHelpers::CharacterIO.new" do
  it "raises ArgumentError if the buffered_io delegate is nil" do
    -> do
      IO::LikeHelpers::CharacterIO.new(nil)
    end.should raise_error(ArgumentError, 'buffered_io cannot be nil')
  end

  it "raises ArgumentError if the blocking_io delegate is nil" do
    buffered_io = mock("buffered_io")
    -> do
      IO::LikeHelpers::CharacterIO.new(buffered_io, nil)
    end.should raise_error(ArgumentError, 'blocking_io cannot be nil')
  end

  it "raises ArgumentError when external encoding is nil and internal encoding is not" do
    buffered_io = mock("buffered_io")
    -> {
      IO::LikeHelpers::CharacterIO.new(buffered_io, internal_encoding: Encoding::UTF_8)
    }.should raise_error(ArgumentError, "external encoding cannot be nil when internal encoding is not nil")
  end

  it "raises ArgumentError when newline decorator encoding option has invalid value" do
    buffered_io = mock("buffered_io")
    -> {
      IO::LikeHelpers::CharacterIO.new(buffered_io, encoding_opts: {newline: :invalid})
    }.should raise_error(ArgumentError, "unexpected value for newline option: invalid")
  end
end

# vim: ts=2 sw=2 et
