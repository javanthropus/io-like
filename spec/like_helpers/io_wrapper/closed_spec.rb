# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::IOWrapper#closed?" do
  before :each do
    @name = tmp('io_wrapper_closed.txt')
    touch @name
    @io = File.open(@name)
  end

  after :each do
    @io.close
    rm_r @name
  end

  it "returns true when the stream is closed" do
    io = IO::LikeHelpers::IOWrapper.new(@io, autoclose: false)
    io.close
    io.closed?.should be_true
  end

  it "returns false when the stream is not closed" do
    io = IO::LikeHelpers::IOWrapper.new(@io)
    io.closed?.should be_false
  end
end

# vim: ts=2 sw=2 et
