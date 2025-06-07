# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::AbstractIO#nonblock=" do
  it "raises NotImplementedError" do
    io = IO::LikeHelpers::AbstractIO.new
    -> { io.send(:nonblock=, true) }.should raise_error(NotImplementedError)
  end
end

describe "IO::LikeHelpers::AbstractIO#nonblock?" do
  it "raises NotImplementedError" do
    io = IO::LikeHelpers::AbstractIO.new
    -> { io.nonblock? }.should raise_error(NotImplementedError)
  end
end

describe "IO::LikeHelpers::AbstractIO#nonblock" do
  it "enables nonblocking mode by default and yields self to the block" do
    io = IO::LikeHelpers::AbstractIO.new
    io.should_receive(:nonblock?).and_return(false)
    io.should_receive(:nonblock=).with(true).and_return(true)
    io.should_receive(:nonblock=).with(false).and_return(false)

    io.nonblock do |self_io|
      self_io.should == io
    end
  end

  it "enables nonblocking mode when directed and yields self to the block" do
    io = IO::LikeHelpers::AbstractIO.new
    io.should_receive(:nonblock?).and_return(false)
    io.should_receive(:nonblock=).with(true).and_return(true)
    io.should_receive(:nonblock=).with(false).and_return(false)

    io.nonblock(true) do |self_io|
      self_io.should == io
    end
  end

  it "disables nonblocking mode when directed and yields self to the block" do
    io = IO::LikeHelpers::AbstractIO.new
    io.should_receive(:nonblock?).and_return(true)
    io.should_receive(:nonblock=).with(false).and_return(false)
    io.should_receive(:nonblock=).with(true).and_return(true)

    io.nonblock(false) do |self_io|
      self_io.should == io
    end
  end

  it "raises IOError if the stream is closed" do
    io = IO::LikeHelpers::AbstractIO.new
    io.close
    -> { io.nonblock(true) { |self_io| } }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
