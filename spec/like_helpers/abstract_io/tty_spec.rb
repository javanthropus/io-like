# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::AbstractIO#tty?" do
  it "returns false" do
    io = IO::LikeHelpers::AbstractIO.new
    io.tty?.should be_false
  end

  it "raises IOError when the stream is closed" do
    io = IO::LikeHelpers::AbstractIO.new
    io.close
    -> { io.tty? }.should raise_error(IOError, "closed stream")
  end
end

# vim: ts=2 sw=2 et
