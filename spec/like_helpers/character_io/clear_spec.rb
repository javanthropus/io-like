# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

require 'io/like_helpers/buffered_io'
require 'io/like_helpers/character_io'
require 'io/like_helpers/io_wrapper'

describe "IO::LikeHelpers::CharacterIO#clear" do
  before :each do
    @fname = tmp('CharacterIO#clear-data.txt')
    File.open(@fname, 'w') { |f| f.write("123") }
    @buffered_io = IO::LikeHelpers::BufferedIO.new(
      IO::LikeHelpers::IOWrapper.new(File.new(@fname))
    )
  end

  after :each do
    @buffered_io.close
    rm_r @fname
  end

  it "resets the state of the character reader when not converting characters" do
    io = IO::LikeHelpers::CharacterIO.new(@buffered_io)
    io.unread('a')
    io.clear
    io.read_char.should == '1'
  end

  it "resets the state of the character reader when converting characters" do
    io = IO::LikeHelpers::CharacterIO.new(
      @buffered_io,
      external_encoding: Encoding::UTF_8,
      internal_encoding: Encoding::UTF_16LE,
    )
    io.unread('a'.encode(Encoding::UTF_16LE))
    io.clear
    io.read_char.should == '1'.encode(Encoding::UTF_16LE)
  end
end

# vim: ts=2 sw=2 et
