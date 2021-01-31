# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::AbstractIO#closed?" do
  it "returns true when the stream is closed" do
    io = IO::LikeHelpers::AbstractIO.new
    io.close
    io.closed?.should be_true
  end

  it "returns false when the stream is not closed" do
    io = IO::LikeHelpers::AbstractIO.new
    io.closed?.should be_false
  end
end

# vim: ts=2 sw=2 et
