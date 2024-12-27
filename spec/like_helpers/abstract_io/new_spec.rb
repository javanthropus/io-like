# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::AbstractIO.new" do
  it "opens the stream" do
    io = IO::LikeHelpers::AbstractIO.new
    io.closed?.should be_false
  end
end

# vim: ts=2 sw=2 et
