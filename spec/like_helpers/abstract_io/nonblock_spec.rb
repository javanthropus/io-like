# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::AbstractIO#nonblock=" do
  it "raises NotImplementedError" do
    io = IO::LikeHelpers::AbstractIO.new
    -> { io.send(:nonblock=, true) }.should raise_error(NotImplementedError)
  end
end

describe "IO::LikeHelpers::AbstractIO#nonblock?" do
  it "raises NotImplementedError" do
    io = IO::LikeHelpers::AbstractIO.new
    -> { io.nonblock? }.should raise_error(NotImplementedError)
  end
end

# vim: ts=2 sw=2 et
