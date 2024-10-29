# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

require 'io/like_helpers/character_io'

describe "IO::LikeHelpers::CharacterIO#unread" do
  it "raises IOError if the delegate is not readable" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(false)

    io = IO::LikeHelpers::CharacterIO.new(
      obj,
      external_encoding: Encoding::UTF_8,
      internal_encoding: Encoding::UTF_16LE
    )
    -> { io.unread("a".encode(Encoding::UTF_16LE)) }.should raise_error(IOError)
  end

  it "raises ArgumentError for invalid length" do
    obj = mock("io")

    io = IO::LikeHelpers::CharacterIO.new(
      obj,
      external_encoding: Encoding::UTF_8,
      internal_encoding: Encoding::UTF_16LE
    )
    -> do
      io.unread("a".encode(Encoding::UTF_16LE), length: -1)
    end.should raise_error(ArgumentError)
  end

  describe "when transcoding" do
    it "returns nil" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)

      io = IO::LikeHelpers::CharacterIO.new(
        obj,
        external_encoding: Encoding::UTF_8,
        internal_encoding: Encoding::UTF_16LE
      )
      io.unread("a".encode(Encoding::UTF_16LE)).should be_nil
    end

    it "pushes to the internal buffer" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)

      io = IO::LikeHelpers::CharacterIO.new(
        obj,
        external_encoding: Encoding::UTF_8,
        internal_encoding: Encoding::UTF_16LE
      )
      # This should not call the delegate's #unread method.
      io.unread("a".encode(Encoding::UTF_16LE)).should be_nil
      io.read_char.should == "a".encode(Encoding::UTF_16LE)
    end
  end

  describe "when not transcoding and with the universal newline decorator" do
    it "returns nil" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)

      io = IO::LikeHelpers::CharacterIO.new(
        obj,
        external_encoding: Encoding::UTF_8,
        encoding_opts: {newline: :universal}
      )
      io.unread("a".encode(Encoding::UTF_16LE)).should be_nil
    end

    it "pushes to the internal buffer" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)

      io = IO::LikeHelpers::CharacterIO.new(
        obj,
        external_encoding: Encoding::UTF_8,
        encoding_opts: {newline: :universal}
      )
      io.unread("a").should be_nil
      io.read_char.should == "a"
    end
  end

  describe "when not transcoding and without the universal newline decorator" do
    it "returns nil" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)

      bio = IO::LikeHelpers::BufferedIO.new(obj)
      io = IO::LikeHelpers::CharacterIO.new(
        bio,
        external_encoding: Encoding::UTF_8
      )
      io.unread("a".encode(Encoding::UTF_16LE)).should be_nil
    end

    it "raises IOError if the internal buffer capacity would be exceeded" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)

      bio = IO::LikeHelpers::BufferedIO.new(obj)
      io = IO::LikeHelpers::CharacterIO.new(
        bio,
        external_encoding: Encoding::UTF_8
      )
      -> { io.unread("\0" * (131072 + 1)) }.should raise_error(IOError)
    end

    it "pushes to the delegate" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      obj.should_receive(:unread).with("a", length: 1).and_return(nil)

      io = IO::LikeHelpers::CharacterIO.new(
        obj,
        external_encoding: Encoding::UTF_8
      )
      io.unread("a").should be_nil
    end

    it "raises exceptions raised by the delegate" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      obj.should_receive(:unread).with("a", length: 1).and_raise(IOError.new)

      io = IO::LikeHelpers::CharacterIO.new(
        obj,
        external_encoding: Encoding::UTF_8
      )
      -> { io.unread("a") }.should raise_error(IOError)
    end
  end
end

# vim: ts=2 sw=2 et
