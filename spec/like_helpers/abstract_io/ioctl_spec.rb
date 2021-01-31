# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::AbstractIO#ioctl" do
  it "raises NotImplementedError" do
    io = IO::LikeHelpers::AbstractIO.new
    -> { io.ioctl(0, 1) }.should raise_error(NotImplementedError)
  end
end

# vim: ts=2 sw=2 et
