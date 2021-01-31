# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::IOWrapper#wait" do
  before :each do
    @name = tmp('io_wrapper_wait.txt')
    touch @name
    @io = File.open(@name)
  end

  after :each do
    @io.close
    rm_r @name
  end

  it "delegates to its delegate and returns non-false" do
    io = IO::LikeHelpers::IOWrapper.new(@io)
    io.wait(IO::READABLE, 1).should be_true
    io = IO::LikeHelpers::IOWrapper.new(@io)
    io.wait(IO::WRITABLE, 1).should be_true
    io = IO::LikeHelpers::IOWrapper.new(@io)
    io.wait(IO::READABLE | IO::WRITABLE, 1).should be_true
  end

  it "returns false when events is an invalid number" do
    io = IO::LikeHelpers::IOWrapper.new(@io)
    io.wait(16, 1).should be_false
  end
end
