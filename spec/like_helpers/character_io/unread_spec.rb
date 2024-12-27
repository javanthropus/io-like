# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

require 'io/like_helpers/character_io'

describe "IO::LikeHelpers::CharacterIO#unread" do
  it "raises IOError if the delegate is not readable" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(false)
    io = IO::LikeHelpers::CharacterIO.new(obj)

    -> { io.unread("a") }.should raise_error(IOError)
  end

  it "raises ArgumentError for invalid length" do
    obj = mock("io")
    io = IO::LikeHelpers::CharacterIO.new(obj)

    -> {
      io.unread("a", length: -1)
    }.should raise_error(ArgumentError)
  end

  describe "when transcoding" do
    before :each do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)

      @io = IO::LikeHelpers::CharacterIO.new(
        obj,
        external_encoding: Encoding::UTF_8,
        internal_encoding: Encoding::UTF_16LE
      )
    end

    it "returns nil" do
      @io.unread("a".encode(Encoding::UTF_16LE)).should be_nil
    end

    it "pushes to the internal buffer" do
      # This should not call the delegate's #unread method.
      @io.unread("a".encode(Encoding::UTF_16LE)).should be_nil
      @io.read_char.should == "a".encode(Encoding::UTF_16LE)
    end

    it "creates a buffer large enough for the given data" do
      content = "\0" * (IO::LikeHelpers::CharacterIO::ConverterReader::MIN_BUFFER_SIZE + 1)
      @io.unread(content).should be_nil
    end

    it "raises IOError when the buffer is full" do
      # This will create the character buffer with the minimum size.
      @io.unread("a").should be_nil
      -> {
        @io.unread(
          "a" * IO::LikeHelpers::CharacterIO::ConverterReader::MIN_BUFFER_SIZE
        )
      }.should raise_error(IOError, "insufficient buffer space for unread")
    end
  end

  describe "when not transcoding and with the universal newline decorator" do
    before :each do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)

      @io = IO::LikeHelpers::CharacterIO.new(
        obj,
        external_encoding: Encoding::UTF_8,
        encoding_opts: {newline: :universal}
      )
    end

    it "returns nil" do
      @io.unread("a".encode(Encoding::UTF_16LE)).should be_nil
    end

    it "pushes to the internal buffer" do
      @io.unread("a").should be_nil
      @io.read_char.should == "a"
    end

    it "creates a buffer large enough for the given data" do
      content = "\0" * (IO::LikeHelpers::CharacterIO::ConverterReader::MIN_BUFFER_SIZE + 1)
      @io.unread(content).should be_nil
    end

    it "raises IOError when the buffer is full" do
      # This will create the character buffer with the minimum size.
      @io.unread("a").should be_nil
      -> {
        @io.unread(
          "a" * IO::LikeHelpers::CharacterIO::ConverterReader::MIN_BUFFER_SIZE
        )
      }.should raise_error(IOError, "insufficient buffer space for unread")
    end
  end

  describe "when not transcoding and without the universal newline decorator" do
    before :each do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)

      bio = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
      @io = IO::LikeHelpers::CharacterIO.new(
        bio,
        external_encoding: Encoding::UTF_8
      )
    end

    it "returns nil" do
      @io.unread("a".encode(Encoding::UTF_16LE)).should be_nil
    end

    it "pushes to the internal buffer" do
      @io.unread("a").should be_nil
      @io.read_char.should == "a"
    end

    it "raises IOError when the buffer is full" do
      -> {
        @io.unread(
          "\0" * (IO::LikeHelpers::BufferedIO::DEFAULT_BUFFER_SIZE + 1)
        )
      }.should raise_error(IOError, "insufficient buffer space for unread")
    end
  end
end

# vim: ts=2 sw=2 et
