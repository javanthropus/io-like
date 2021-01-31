# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::IOWrapper#writable?" do
  before :each do
    @pipe_r, @pipe_w = IO.pipe
  end

  after :each do
    @pipe_r.close
    @pipe_w.close
  end

  it "delegates to its delegate" do
    io = IO::LikeHelpers::IOWrapper.new(@pipe_w)
    io.writable?.should be_true
    io = IO::LikeHelpers::IOWrapper.new(@pipe_r)
    io.writable?.should be_false
  end
end

# vim: ts=2 sw=2 et
