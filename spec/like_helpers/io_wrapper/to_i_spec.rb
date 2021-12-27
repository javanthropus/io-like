# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'
require_relative '../../../rubyspec/core/io/fixtures/classes'

describe "IO::LikeHelpers::IOWrapper#to_i" do
  before :each do
    @name = tmp('io_wrapper_to_i.txt')
    touch @name
    @io = File.open(@name)
  end

  after :each do
    @io.close
    rm_r @name
  end

  it "delegates to its delegate" do
    io = IO::LikeHelpers::IOWrapper.new(@io)
    io.to_i.should == @io.to_i
  end
end

# vim: ts=2 sw=2 et