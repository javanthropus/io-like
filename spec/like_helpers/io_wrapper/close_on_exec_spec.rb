# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::IOWrapper#close_on_exec=" do
  before :each do
    @name = tmp('io_wrapper_close_on_exec.txt')
    touch @name
    @io = File.open(@name)
  end

  after :each do
    @io.close
    rm_r @name
  end

  it "delegates to its delegate" do
    io = IO::LikeHelpers::IOWrapper.new(@io)
    io.send(:close_on_exec=, true).should be_nil
  end

  it "raises IOError when its delegate raises it" do
    io = IO::LikeHelpers::IOWrapper.new(@io)
    @io.close
    -> { io.send(:close_on_exec=, true) }.should raise_error(IOError, 'closed stream')
  end
end

describe "IO::LikeHelpers::IOWrapper#close_on_exec?" do
  before :each do
    @name = tmp('io_wrapper_close_on_exec.txt')
    touch @name
    @io = File.open(@name)
  end

  after :each do
    @io.close
    rm_r @name
  end

  it "delegates to its delegate" do
    io = IO::LikeHelpers::IOWrapper.new(@io)
    io.close_on_exec?.should be_true
  end

  it "raises IOError when its delegate raises it" do
    io = IO::LikeHelpers::IOWrapper.new(@io)
    @io.close
    -> { io.close_on_exec? }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
