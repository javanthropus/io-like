# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'
require_relative '../../../rubyspec/core/io/fixtures/classes'

describe "IO::LikeHelpers::AbstractIO#isatty" do
  it "returns false" do
    io = IO::LikeHelpers::AbstractIO.new
    io.isatty.should be_false
  end

  it "raises IOError when the stream is closed" do
    io = IO::LikeHelpers::AbstractIO.new
    io.close
    -> { io.isatty }.should raise_error(IOError, "closed stream")
  end
end

# vim: ts=2 sw=2 et
