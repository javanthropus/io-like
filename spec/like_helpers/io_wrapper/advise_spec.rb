# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::IOWrapper#advise" do
  before :each do
    @name = tmp('io_wrapper_advise.txt')
    touch @name
    @io = File.open(@name)
  end

  after :each do
    @io.close
    rm_r @name
  end

  it "delegates to its delegate" do
    io = IO::LikeHelpers::IOWrapper.new(@io)
    io.advise(:normal).should be_nil
  end

  it "raises IOError when its delegate raises it" do
    io = IO::LikeHelpers::IOWrapper.new(@io)
    @io.close
    -> { io.advise(:normal) }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
