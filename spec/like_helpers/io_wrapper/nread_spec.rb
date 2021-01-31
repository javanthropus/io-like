# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::IOWrapper#nread" do
  before :each do
    @name = tmp('io_wrapper_nread.txt')
    touch @name
    @io = File.open(@name)
  end

  after :each do
    @io.close
    rm_r @name
  end

  it "delegates to its delegate" do
    io = IO::LikeHelpers::IOWrapper.new(@io)
    io.nread.should == 0
  end
end
