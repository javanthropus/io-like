# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::AbstractIO#close_on_exec=" do
  it "raises NotImplementedError" do
    io = IO::LikeHelpers::AbstractIO.new
    -> { io.send(:close_on_exec=, true) }.should raise_error(NotImplementedError)
  end
end

describe "IO::LikeHelpers::AbstractIO#close_on_exec?" do
  it "raises NotImplementedError" do
    io = IO::LikeHelpers::AbstractIO.new
    -> { io.close_on_exec? }.should raise_error(NotImplementedError)
  end
end

# vim: ts=2 sw=2 et
