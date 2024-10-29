# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

require 'io/like_helpers/character_io'

describe "IO::LikeHelpers::CharacterIO#set_encoding" do
  it "sets the internal and external encoding of the stream" do
    obj = mock("io")
    io = IO::LikeHelpers::CharacterIO.new(obj)
    io.set_encoding(Encoding::UTF_8, Encoding::UTF_16LE)
    io.external_encoding.should == Encoding::UTF_8
    io.internal_encoding.should == Encoding::UTF_16LE

    io.set_encoding(Encoding::UTF_8, nil)
    io.external_encoding.should == Encoding::UTF_8
    io.internal_encoding.should be_nil
  end

  it "requires the external encoding to be provided if the internal encoding is provided" do
    obj = mock("io")
    io = IO::LikeHelpers::CharacterIO.new(obj)
    -> { io.set_encoding(nil, Encoding::UTF_8) }.should raise_error(ArgumentError)
  end

  it "sets the internal encoding to nil if it is the same as the external encoding" do
    obj = mock("io")
    io = IO::LikeHelpers::CharacterIO.new(obj)
    io.set_encoding(Encoding::UTF_8, Encoding::UTF_8)
    io.external_encoding.should == Encoding::UTF_8
    io.internal_encoding.should be_nil
  end

  it "sets the newline decorator" do
    skip
  end

  it "unsets the newline decorator" do
    skip
  end
end

# vim: ts=2 sw=2 et
