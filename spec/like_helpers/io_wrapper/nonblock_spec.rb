# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::IOWrapper#nonblock=" do
  before :each do
    @name = tmp('io_wrapper_nonblock.txt')
    touch @name
    @io = File.open(@name)
  end

  after :each do
    @io.close
    rm_r @name
  end

  it "delegates to its delegate" do
    io = IO::LikeHelpers::IOWrapper.new(@io)
    @io.nonblock?.should be_false
    io.send(:nonblock=, true).should be_true
    @io.nonblock?.should be_true
  end

  it "raises IOError when its delegate raises it" do
    io = IO::LikeHelpers::IOWrapper.new(@io)
    @io.close
    -> { io.send(:nonblock=, true) }.should raise_error(IOError, 'closed stream')
  end
end

describe "IO::LikeHelpers::IOWrapper#nonblock?" do
  before :each do
    @name = tmp('io_wrapper_nonblock.txt')
    touch @name
    @io = File.open(@name)
  end

  after :each do
    @io.close
    rm_r @name
  end

  it "delegates to its delegate" do
    io = IO::LikeHelpers::IOWrapper.new(@io)
    @io.nonblock = true
    io.nonblock?.should be_true
    @io.nonblock = false
    io.nonblock?.should be_false
  end

  it "raises IOError when the delegate is closed" do
    io = IO::LikeHelpers::IOWrapper.new(@io)
    @io.close
    -> { io.nonblock? }.should raise_error(IOError, 'closed stream')
  end
end

describe "IO::LikeHelpers::IOWrapper#nonblock" do
  before :each do
    @name = tmp('io_wrapper_nonblock.txt')
    touch @name
    @io = File.open(@name)
  end

  after :each do
    @io.close
    rm_r @name
  end

  it "enables nonblocking mode by default and yields self to the block" do
    io = IO::LikeHelpers::IOWrapper.new(@io)
    io.nonblock do |self_io|
      @io.nonblock?.should be_true
      self_io.should == io
    end
    @io.nonblock?.should be_false
  end

  it "enables nonblocking mode when directed and yields self to the block" do
    io = IO::LikeHelpers::IOWrapper.new(@io)
    io.nonblock(true) do |self_io|
      @io.nonblock?.should be_true
      self_io.should == io
    end
    @io.nonblock?.should be_false
  end

  it "disables nonblocking mode when directed and yields self to the block" do
    io = IO::LikeHelpers::IOWrapper.new(@io)
    @io.nonblock = true
    io.nonblock(false) do |self_io|
      @io.nonblock?.should be_false
      self_io.should == io
    end
    @io.nonblock?.should be_true
  end

  it "raises IOError when the delegate is closed" do
    io = IO::LikeHelpers::IOWrapper.new(@io)
    @io.close
    -> { io.nonblock { |self_io| } }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
