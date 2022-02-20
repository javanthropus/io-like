# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::AbstractIO#fcntl" do
  it "raises NotImplementedError" do
    io = IO::LikeHelpers::AbstractIO.new
    -> { io.fcntl(0, 0) }.should raise_error(NotImplementedError)
  end
end

# vim: ts=2 sw=2 et
