# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::IOWrapper#dup" do
  before :each do
    @name = tmp('io_wrapper_dup.txt')
    touch @name
    @io = File.open(@name)
  end

  after :each do
    @io.close
    rm_r @name
  end

  it "dups the delegate" do
    @io.should_receive(:dup).and_return(@io.dup)
    io = IO::LikeHelpers::IOWrapper.new(@io)
  end
end

# vim: ts=2 sw=2 et
