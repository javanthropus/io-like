# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

require 'io/like_helpers/character_io'

describe "IO::LikeHelpers::CharacterIO#write" do
  it "raises IOError if the delegate is not writable" do
    content = "a"
    obj = mock("io")
    obj.should_receive(:writable?).and_return(false)
    io = IO::LikeHelpers::CharacterIO.new(obj)
    -> { io.write(content) }.should raise_error(IOError)
  end

  describe "when no encoding is given" do
    it "writes binary data" do
      content = "Hëllö\n".encode('ISO-8859-1')
      obj = mock("io")
      obj.should_receive(:writable?).and_return(true)
      obj.should_receive(:write).with(content.b)
        .and_return(content.bytesize)
      io = IO::LikeHelpers::CharacterIO.new(obj)
      io.write(content).should == content.bytesize
    end

    it "writes everything even when the delegate performs partial writes" do
      content = "Hëllö\n".encode('ISO-8859-1')
      obj = mock("io")
      obj.should_receive(:writable?).and_return(true)
      obj.should_receive(:write).with(content.b).and_return(2)
      obj.should_receive(:write).with(content.b[2..-1])
        .and_return(content.bytesize - 2)
      io = IO::LikeHelpers::CharacterIO.new(obj)
      io.write(content).should == content.bytesize
    end

    it "converts line feed to carriage return when configured to do so" do
      content = "Hëllö\n".encode('ISO-8859-1')
      converted_content = content.encode(newline: :cr)
      obj = mock("io")
      obj.should_receive(:writable?).and_return(true)
      obj.should_receive(:write).with(converted_content.b)
        .and_return(converted_content.bytesize)
      io = IO::LikeHelpers::CharacterIO.new(
        obj,
        encoding_opts: {newline: :cr}
      )
      io.write(content).should == converted_content.bytesize
    end

    it "converts line feed to carriage return, line feed pair when configured to do so" do
      content = "Hëllö\n".encode('ISO-8859-1')
      converted_content = content.encode(newline: :crlf)
      obj = mock("io")
      obj.should_receive(:writable?).and_return(true)
      obj.should_receive(:write).with(converted_content.b)
        .and_return(converted_content.bytesize)
      io = IO::LikeHelpers::CharacterIO.new(
        obj,
        encoding_opts: {newline: :crlf}
      )
      io.write(content).should == converted_content.bytesize
    end

    it "converts carriage return to line feed when configured to do so" do
      content = "Hëllö\r".encode('ISO-8859-1')
      converted_content = content.encode(newline: :lf)
      obj = mock("io")
      obj.should_receive(:writable?).and_return(true)
      obj.should_receive(:write).with(converted_content.b)
        .and_return(converted_content.bytesize)
      io = IO::LikeHelpers::CharacterIO.new(
        obj,
        encoding_opts: {newline: :lf}
      )
      io.write(content).should == converted_content.bytesize
    end

    it "ignores universal newline conversion" do
      content = "Hëllö\n".encode('ISO-8859-1')
      obj = mock("io")
      obj.should_receive(:writable?).and_return(true)
      obj.should_receive(:write).with(content.b)
        .and_return(content.bytesize)
      io = IO::LikeHelpers::CharacterIO.new(
        obj,
        encoding_opts: {newline: :universal}
      )
      io.write(content).should == content.bytesize
    end
  end

  describe "when the encoding is ASCII-8BIT" do
    it "writes binary data" do
      content = "Hëllö\n".encode('ISO-8859-1')
      obj = mock("io")
      obj.should_receive(:writable?).and_return(true)
      obj.should_receive(:write).with(content.b)
        .and_return(content.bytesize)
      io = IO::LikeHelpers::CharacterIO.new(
        obj,
        external_encoding: Encoding::ASCII_8BIT
      )
      io.write(content).should == content.bytesize
    end

    it "writes everything even when the delegate performs partial writes" do
      content = "Hëllö\n".encode('ISO-8859-1')
      obj = mock("io")
      obj.should_receive(:writable?).and_return(true)
      obj.should_receive(:write).with(content.b).and_return(2)
      obj.should_receive(:write).with(content.b[2..-1])
        .and_return(content.bytesize - 2)
      io = IO::LikeHelpers::CharacterIO.new(
        obj,
        external_encoding: Encoding::ASCII_8BIT
      )
      io.write(content).should == content.bytesize
    end

    it "converts line feed to carriage return when configured to do so" do
      content = "Hëllö\n".encode('ISO-8859-1')
      converted_content = content.encode(newline: :cr)
      obj = mock("io")
      obj.should_receive(:writable?).and_return(true)
      obj.should_receive(:write).with(converted_content.b)
        .and_return(converted_content.bytesize)
      io = IO::LikeHelpers::CharacterIO.new(
        obj,
        external_encoding: Encoding::ASCII_8BIT,
        encoding_opts: {newline: :cr}
      )
      io.write(content).should == converted_content.bytesize
    end

    it "converts line feed to carriage return, line feed pair when configured to do so" do
      content = "Hëllö\n".encode('ISO-8859-1')
      converted_content = content.encode(newline: :crlf)
      obj = mock("io")
      obj.should_receive(:writable?).and_return(true)
      obj.should_receive(:write).with(converted_content.b)
        .and_return(converted_content.bytesize)
      io = IO::LikeHelpers::CharacterIO.new(
        obj,
        external_encoding: Encoding::ASCII_8BIT,
        encoding_opts: {newline: :crlf}
      )
      io.write(content).should == converted_content.bytesize
    end

    it "converts carriage return to line feed when configured to do so" do
      content = "Hëllö\r".encode('ISO-8859-1')
      converted_content = content.encode(newline: :lf)
      obj = mock("io")
      obj.should_receive(:writable?).and_return(true)
      obj.should_receive(:write).with(converted_content.b)
        .and_return(converted_content.bytesize)
      io = IO::LikeHelpers::CharacterIO.new(
        obj,
        external_encoding: Encoding::ASCII_8BIT,
        encoding_opts: {newline: :lf}
      )
      io.write(content).should == converted_content.bytesize
    end

    it "ignores universal newline conversion" do
      content = "Hëllö\n".encode('ISO-8859-1')
      obj = mock("io")
      obj.should_receive(:writable?).and_return(true)
      obj.should_receive(:write).with(content.b)
        .and_return(content.bytesize)
      io = IO::LikeHelpers::CharacterIO.new(
        obj,
        external_encoding: Encoding::ASCII_8BIT,
        encoding_opts: {newline: :universal}
      )
      io.write(content).should == content.bytesize
    end
  end

  describe "when transcoding" do
    it "converts to the external encoding and returns the number of bytes given" do
      content = "a"
      converted_content = content.encode(Encoding::UTF_16LE)
      obj = mock("io")
      obj.should_receive(:writable?).and_return(true)
      obj.should_receive(:write).with(converted_content.b)
        .and_return(converted_content.bytesize)
      io = IO::LikeHelpers::CharacterIO.new(
        obj,
        external_encoding: Encoding::UTF_16LE
      )
      io.write(content).should == converted_content.bytesize
    end

    it "writes everything even when the delegate performs partial writes" do
      content = "abc"
      converted_content = content.encode(Encoding::UTF_16LE)
      obj = mock("io")
      obj.should_receive(:writable?).and_return(true)
      obj.should_receive(:write).with(converted_content.b).and_return(2)
      obj.should_receive(:write).with(converted_content.b[2..-1])
        .and_return(converted_content.bytesize - 2)
      io = IO::LikeHelpers::CharacterIO.new(
        obj,
        external_encoding: Encoding::UTF_16LE
      )
      io.write(content).should == converted_content.bytesize
    end

    it "converts line feed to carriage return when configured to do so" do
      content = "a\nb\nc"
      converted_content = content.encode(Encoding::UTF_16LE, newline: :cr)
      obj = mock("io")
      obj.should_receive(:writable?).and_return(true)
      obj.should_receive(:write).with(converted_content.b)
        .and_return(converted_content.bytesize)
      io = IO::LikeHelpers::CharacterIO.new(
        obj,
        external_encoding: Encoding::UTF_16LE,
        encoding_opts: {newline: :cr}
      )
      io.write(content).should == converted_content.bytesize
    end

    it "converts line feed to carriage return, line feed pair when configured to do so" do
      content = "a\nb\rc"
      converted_content = content.encode(Encoding::UTF_16LE, newline: :crlf)
      obj = mock("io")
      obj.should_receive(:writable?).and_return(true)
      obj.should_receive(:write).with(converted_content.b)
        .and_return(converted_content.bytesize)
      io = IO::LikeHelpers::CharacterIO.new(
        obj,
        external_encoding: Encoding::UTF_16LE,
        encoding_opts: {newline: :crlf}
      )
      io.write(content).should == converted_content.bytesize
    end

    it "converts carriage return to line feed when configured to do so" do
      content = "a\rb\rc"
      converted_content = content.encode(Encoding::UTF_16LE, newline: :lf)
      obj = mock("io")
      obj.should_receive(:writable?).and_return(true)
      obj.should_receive(:write).with(converted_content.b)
        .and_return(converted_content.bytesize)
      io = IO::LikeHelpers::CharacterIO.new(
        obj,
        external_encoding: Encoding::UTF_16LE,
        encoding_opts: {newline: :lf}
      )
      io.write(content).should == converted_content.bytesize
    end

    it "ignores universal newline conversion" do
      content = "a\rb\nc"
      converted_content = content.encode(Encoding::UTF_16LE)
      obj = mock("io")
      obj.should_receive(:writable?).and_return(true)
      obj.should_receive(:write).with(converted_content.b)
        .and_return(converted_content.bytesize)
      io = IO::LikeHelpers::CharacterIO.new(
        obj,
        external_encoding: Encoding::UTF_16LE,
        encoding_opts: {newline: :universal}
      )
      io.write(content).should == converted_content.bytesize
    end
  end
end

# vim: ts=2 sw=2 et
