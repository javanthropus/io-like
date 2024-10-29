# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

require 'io/like_helpers/character_io'

describe "IO::LikeHelpers::CharacterIO.new" do
  it "raises ArgumentError if the delegate is nil" do
    -> do
      IO::LikeHelpers::CharacterIO.new(nil, external_encoding: nil, internal_encoding: nil)
    end.should raise_error(ArgumentError, 'buffered_io cannot be nil')
  end
end

# vim: ts=2 sw=2 et
