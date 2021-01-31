# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::AbstractIO#write" do
  it "raises IOError if the stream is not writable" do
    buffer = 'foo'.b
    io = IO::LikeHelpers::AbstractIO.new
    -> { io.write(buffer) }.should raise_error(IOError, 'not opened for writing')
  end

  it "raises IOError if the stream is closed" do
    buffer = 'foo'.b
    io = IO::LikeHelpers::AbstractIO.new
    io.close
    -> { io.write(buffer) }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
