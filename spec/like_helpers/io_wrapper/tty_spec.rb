# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::IOWrapper#tty?" do
  before :each do
    @name = tmp('io_wrapper_tty.txt')
    touch @name
    @io = File.open(@name)
  end

  after :each do
    @io.close
    rm_r @name
  end

  it "delegates to its delegate" do
    io = IO::LikeHelpers::IOWrapper.new(@io)
    io.tty?.should be_false
  end
end

# vim: ts=2 sw=2 et
