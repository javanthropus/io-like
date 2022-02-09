# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::AbstractIO#pid" do
  it "returns nil" do
    io = IO::LikeHelpers::AbstractIO.new
    io.pid.should be_nil
  end
end

# vim: ts=2 sw=2 et
