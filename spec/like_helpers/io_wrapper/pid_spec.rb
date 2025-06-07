# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::IOWrapper#pid" do
  before :each do
    @io = IO.popen('echo')
  end

  after :each do
    @io.close
  end

  it "delegates to its delegate" do
    io = IO::LikeHelpers::IOWrapper.new(@io)
    io.pid.should > 0
  end
end

# vim: ts=2 sw=2 et
