# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::IOWrapper#autoclose=" do
  before :each do
    @name = tmp('io_wrapper_autoclose.txt')
    touch @name
    @io = File.open(@name)
  end

  after :each do
    @io.close
    rm_r @name
  end

  it "returns the argument given" do
    io = IO::LikeHelpers::IOWrapper.new(@io)
    io.send(:autoclose=, true).should be_true
    io.send(:autoclose=, false).should be_false
    io.send(:autoclose=, :foo).should == :foo
  end
end

describe "IO::LikeHelpers::IOWrapper#autoclose?" do
  before :each do
    @name = tmp('io_wrapper_autoclose.txt')
    touch @name
    @io = File.open(@name)
  end

  after :each do
    @io.close
    rm_r @name
  end

  it "returns the truthiness of #autoclose=" do
    obj = mock("io")
    io = IO::LikeHelpers::IOWrapper.new(@io)

    io.autoclose = true
    io.autoclose?.should be_true

    io.autoclose = false
    io.autoclose?.should be_false

    io.autoclose = :foo
    io.autoclose?.should be_true
  end
end

# vim: ts=2 sw=2 et
