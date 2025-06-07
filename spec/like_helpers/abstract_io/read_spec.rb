# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::AbstractIO#read" do
  it "raises IOError if the stream is not readable" do
    io = IO::LikeHelpers::AbstractIO.new
    -> { io.read(1) }.should raise_error(IOError, 'not opened for reading')
  end

  it "raises IOError if the stream is closed" do
    io = IO::LikeHelpers::AbstractIO.new
    io.close
    -> { io.read(1) }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
