# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::IOWrapper#close" do
  before :each do
    @name = tmp('io_wrapper_close.txt')
    touch @name
    @io = File.open(@name)
  end

  after :each do
    @io.close
    rm_r @name
  end

  it "delegates to its delegate when #autoclose? is true" do
    io = IO::LikeHelpers::IOWrapper.new(@io)
    io.close.should be_nil
    @io.closed?.should be_true
  end

  it "does not delegate to its delegate when #autoclose? is false" do
    io = IO::LikeHelpers::IOWrapper.new(@io, autoclose: false)
    io.close.should be_nil
    @io.closed?.should be_false
  end
end

# vim: ts=2 sw=2 et
