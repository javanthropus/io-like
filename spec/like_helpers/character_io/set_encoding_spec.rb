# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

require 'io/like_helpers/buffered_io'
require 'io/like_helpers/character_io'
require 'io/like_helpers/io_wrapper'

describe "IO::LikeHelpers::CharacterIO#set_encoding" do
  before :each do
    @data = "foo\rbar\r\nbaz\n"
    @fname = tmp('CharacterIO#set_encoding-data.txt')
    touch @fname
    @buffered_io = IO::LikeHelpers::BufferedIO.new(
      IO::LikeHelpers::IOWrapper.new(File.new(@fname, 'r+'))
    )
  end

  after :each do
    @buffered_io.close
    rm_r @fname
  end

  it "sets the internal and external encoding of the stream" do
    io = IO::LikeHelpers::CharacterIO.new(@buffered_io)
    io.set_encoding(Encoding::UTF_8, Encoding::UTF_16LE)
    io.external_encoding.should == Encoding::UTF_8
    io.internal_encoding.should == Encoding::UTF_16LE

    io.set_encoding(Encoding::UTF_8, nil)
    io.external_encoding.should == Encoding::UTF_8
    io.internal_encoding.should be_nil
  end

  it "requires the external encoding to be provided if the internal encoding is provided" do
    io = IO::LikeHelpers::CharacterIO.new(@buffered_io)
    -> { io.set_encoding(nil, Encoding::UTF_8) }.should raise_error(ArgumentError)
  end

  it "sets the internal encoding to nil if it is the same as the external encoding" do
    io = IO::LikeHelpers::CharacterIO.new(@buffered_io)
    io.set_encoding(Encoding::UTF_8, Encoding::UTF_8)
    io.external_encoding.should == Encoding::UTF_8
    io.internal_encoding.should be_nil
  end

  it "sets the universal newline decorator when not converting characters" do
    File.binwrite(@fname, @data)
    io = IO::LikeHelpers::CharacterIO.new(@buffered_io)
    io.set_encoding(Encoding::UTF_8, nil, universal_newline: true)
    io.read_line(separator: nil).should == @data.encode(universal_newline: true)
  end

  it "sets the universal newline decorator when converting characters" do
    File.binwrite(@fname, @data)
    io = IO::LikeHelpers::CharacterIO.new(@buffered_io)
    io.set_encoding(Encoding::UTF_8, Encoding::UTF_16LE, universal_newline: true)
    io.read_line(separator: nil).should == @data.encode(Encoding::UTF_16LE, universal_newline: true)
  end

  it "unsets the universal newline decorator when not converting characters" do
    File.binwrite(@fname, @data)
    io = IO::LikeHelpers::CharacterIO.new(@buffered_io)
    io.set_encoding(Encoding::UTF_8, nil, universal_newline: true)
    io.set_encoding(Encoding::UTF_8, nil, universal_newline: false)
    io.read_line(separator: nil).should == @data
  end

  it "unsets the universal newline decorator when converting characters" do
    File.binwrite(@fname, @data)
    io = IO::LikeHelpers::CharacterIO.new(@buffered_io)
    io.set_encoding(Encoding::UTF_8, Encoding::UTF_16LE, universal_newline: true)
    io.set_encoding(Encoding::UTF_8, Encoding::UTF_16LE, universal_newline: false)
    io.read_line(separator: nil).should == @data.encode(Encoding::UTF_16LE, universal_newline: false)
  end

  it "sets the CR newline decorator for writing when not converting characters" do
    io = IO::LikeHelpers::CharacterIO.new(@buffered_io)
    io.set_encoding(Encoding::UTF_8, nil, cr_newline: true)
    io.write(@data)
    @buffered_io.flush
    File.binread(@fname).should == @data.encode(cr_newline: true)
  end

  it "sets the CR newline decorator for writing when converting characters" do
    io = IO::LikeHelpers::CharacterIO.new(@buffered_io)
    io.set_encoding(Encoding::UTF_8, Encoding::UTF_16LE, cr_newline: true)
    io.write(@data)
    @buffered_io.flush
    File.binread(@fname).should == @data.encode(cr_newline: true)
  end

  it "sets the CRLF newline decorator for writing when not converting characters" do
    io = IO::LikeHelpers::CharacterIO.new(@buffered_io)
    io.set_encoding(Encoding::UTF_8, nil, crlf_newline: true)
    io.write(@data)
    @buffered_io.flush
    File.binread(@fname).should == @data.encode(crlf_newline: true)
  end

  it "sets the CRLF newline decorator for writing when converting characters" do
    io = IO::LikeHelpers::CharacterIO.new(@buffered_io)
    io.set_encoding(Encoding::UTF_8, Encoding::UTF_16LE, crlf_newline: true)
    io.write(@data)
    @buffered_io.flush
    File.binread(@fname).should == @data.encode(crlf_newline: true)
  end

  it "sets the LF newline decorator for writing when not converting characters" do
    io = IO::LikeHelpers::CharacterIO.new(@buffered_io)
    io.set_encoding(Encoding::UTF_8, nil, lf_newline: true)
    io.write(@data)
    @buffered_io.flush
    File.binread(@fname).should == @data.encode(lf_newline: true)
  end

  it "sets the LF newline decorator for writing when converting characters" do
    io = IO::LikeHelpers::CharacterIO.new(@buffered_io)
    io.set_encoding(Encoding::UTF_8, Encoding::UTF_16LE, lf_newline: true)
    io.write(@data)
    @buffered_io.flush
    File.binread(@fname).should == @data.encode(lf_newline: true)
  end

  it "sets the invalid byte sequence decorator for reading when converting characters" do
    data = "\xd8\x00\x00@"
    expected_data = "replacement@"
    File.open(@fname, 'wb') { |f| f.write(data) }
    io = IO::LikeHelpers::CharacterIO.new(@buffered_io)
    io.set_encoding(Encoding::UTF_16BE, Encoding::UTF_8, invalid: :replace, replace: 'replacement')
    io.read_line(separator: nil).should == expected_data
  end

  it "sets the invalid byte sequence decorator for writing when converting characters" do
    data = String.new("\xd8\x00\x00@", encoding: Encoding::UTF_16BE)
    expected_data = "replacement@".b
    io = IO::LikeHelpers::CharacterIO.new(@buffered_io)
    io.set_encoding(Encoding::UTF_8, Encoding::UTF_16BE, invalid: :replace, replace: 'replacement')
    io.write(data)
    @buffered_io.flush
    File.binread(@fname).should == expected_data
  end

  it "sets the undefined conversion decorator for reading when converting characters" do
    data = "\xa4\xa2"
    expected_data = String.new("replacement", encoding: Encoding::ISO_8859_1)
    File.open(@fname, 'wb') { |f| f.write(data) }
    io = IO::LikeHelpers::CharacterIO.new(@buffered_io)
    io.set_encoding(Encoding::EUC_JP, Encoding::ISO_8859_1, undef: :replace, replace: 'replacement')
    io.read_line(separator: nil).should == expected_data
  end

  it "sets the undefined conversion decorator for writing when converting characters" do
    data = String.new("\xa4\xa2", encoding: Encoding::EUC_JP)
    expected_data = "replacement".b
    io = IO::LikeHelpers::CharacterIO.new(@buffered_io)
    io.set_encoding(Encoding::ISO_8859_1, Encoding::EUC_JP, undef: :replace, replace: 'replacement')
    io.write(data)
    @buffered_io.flush
    File.binread(@fname).should == expected_data
  end

  it "ignores the CR newline decorator for reading when not converting characters" do
    File.binwrite(@fname, @data)
    io = IO::LikeHelpers::CharacterIO.new(@buffered_io)
    io.set_encoding(Encoding::UTF_8, nil, cr_newline: true)
    io.read_line(separator: nil).should == @data
  end

  it "ignores the CR newline decorator for reading when converting characters" do
    File.binwrite(@fname, @data)
    io = IO::LikeHelpers::CharacterIO.new(@buffered_io)
    io.set_encoding(Encoding::UTF_8, Encoding::UTF_16LE, cr_newline: true)
    io.read_line(separator: nil).should == @data.encode(Encoding::UTF_16LE)
  end

  it "ignores the CRLF newline decorator for reading when not converting characters" do
    File.binwrite(@fname, @data)
    io = IO::LikeHelpers::CharacterIO.new(@buffered_io)
    io.set_encoding(Encoding::UTF_8, nil, crlf_newline: true)
    io.read_line(separator: nil).should == @data
  end

  it "ignores the CRLF newline decorator for reading when converting characters" do
    File.binwrite(@fname, @data)
    io = IO::LikeHelpers::CharacterIO.new(@buffered_io)
    io.set_encoding(Encoding::UTF_8, Encoding::UTF_16LE, crlf_newline: true)
    io.read_line(separator: nil).should == @data.encode(Encoding::UTF_16LE)
  end

  it "ignores the LF newline decorator for reading when not converting characters" do
    File.binwrite(@fname, @data)
    io = IO::LikeHelpers::CharacterIO.new(@buffered_io)
    io.set_encoding(Encoding::UTF_8, nil, lf_newline: true)
    io.read_line(separator: nil).should == @data
  end

  it "ignores the LF newline decorator for reading when converting characters" do
    File.binwrite(@fname, @data)
    io = IO::LikeHelpers::CharacterIO.new(@buffered_io)
    io.set_encoding(Encoding::UTF_8, Encoding::UTF_16LE, lf_newline: true)
    io.read_line(separator: nil).should == @data.encode(Encoding::UTF_16LE)
  end

  it "ignores the universal newline decorator for writing when not converting characters" do
    File.binwrite(@fname, @data)
    io = IO::LikeHelpers::CharacterIO.new(@buffered_io)
    io.set_encoding(Encoding::UTF_8, nil, universal_newline: true)
    io.write(@data)
    @buffered_io.flush
    File.binread(@fname).should == @data
  end

  it "ignores the universal newline decorator for writing when converting characters" do
    File.binwrite(@fname, @data)
    io = IO::LikeHelpers::CharacterIO.new(@buffered_io)
    io.set_encoding(Encoding::UTF_8, Encoding::UTF_16LE, universal_newline: true)
    io.write(@data)
    @buffered_io.flush
    File.binread(@fname).should == @data
  end

  it "ignores the xml decorator for reading when not converting characters" do
    File.binwrite(@fname, @data)
    io = IO::LikeHelpers::CharacterIO.new(@buffered_io)
    io.set_encoding(Encoding::UTF_8, nil, xml: :attr)
    io.read_line(separator: nil).should == @data
  end

  it "ignores the xml decorator for reading when converting characters" do
    File.binwrite(@fname, @data)
    io = IO::LikeHelpers::CharacterIO.new(@buffered_io)
    io.set_encoding(Encoding::UTF_8, Encoding::UTF_16LE, xml: :attr)
    io.read_line(separator: nil).should == @data.encode(Encoding::UTF_16LE)
  end
end

# vim: ts=2 sw=2 et
