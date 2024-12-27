# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::BufferedIO.new" do
  it "raises ArgumentError if the delegate is nil" do
    -> do
      IO::LikeHelpers::BufferedIO.new(nil)
    end.should raise_error(ArgumentError, 'delegate cannot be nil')
  end

  it "requires the buffer size to be greater than zero" do
    obj = mock("io")
    -> do
      IO::LikeHelpers::BufferedIO.new(obj, buffer_size: 0)
    end.should raise_error(ArgumentError, 'buffer_size must be greater than 0')
  end

  it "enables autoclose by default" do
    obj = mock("io")
    obj.should_receive(:close).and_return(nil)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.autoclose?.should be_true
    io.close
  end

  it "allows autoclose to be set" do
    obj = mock("io")
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
    io.autoclose?.should be_false
  end

  it "sets a default buffer size" do
    obj = mock("io")
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
    io.buffer_size.should == 8192
  end

  it "allows the buffer size to be set" do
    obj = mock("io")
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false, buffer_size: 1)
    io.buffer_size.should == 1
  end
end

# vim: ts=2 sw=2 et
