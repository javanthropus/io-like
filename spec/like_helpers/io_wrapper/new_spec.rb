# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::IOWrapper.new" do
  before :each do
    @name = tmp('io_wrapper_new.txt')
    touch @name
    @io = File.open(@name)
  end

  after :each do
    @io.close
    rm_r @name
  end

  it "raises ArgumentError if the delegate is nil" do
    -> { IO::LikeHelpers::IOWrapper.new(nil) }.should raise_error(ArgumentError)
  end

  it "enables autoclose by default" do
    io = IO::LikeHelpers::IOWrapper.new(@io)
    io.autoclose?.should be_true
  end

  it "allows autoclose to be set" do
    io = IO::LikeHelpers::IOWrapper.new(@io, autoclose: false)
    io.autoclose?.should be_false
  end
end

# vim: ts=2 sw=2 et
