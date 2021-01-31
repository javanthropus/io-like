# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DelegatedIO#dup" do
  it "dups the delegate" do
    obj_dup = mock("io_dup")
    obj_dup.should_receive(:readable?).and_return(true)
    obj = mock("io")
    obj.should_receive(:dup).and_return(obj_dup)
    io = IO::LikeHelpers::DelegatedIO.new(obj).dup
    io.readable?.should be_true
  end

  it "raises IOError if the stream is closed" do
    obj = mock("io")
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.close
    -> { io.dup }.should raise_error(IOError, 'closed stream')
  end

  it "raises IOError if the delegate does so" do
    obj = mock("io")
    obj.should_receive(:dup).and_raise(IOError.new('closed stream'))
    io = IO::LikeHelpers::DelegatedIO.new(obj)
    -> { io.dup }.should raise_error(IOError, 'closed stream')
  end

  it "sets the autoclose flag on the new stream" do
    obj_dup = mock("io_dup")
    obj = mock("io")
    obj.should_receive(:dup).and_return(obj_dup).exactly(2)
    io = IO::LikeHelpers::DelegatedIO.new(obj)

    io.autoclose = true
    io_dup = io.dup
    io_dup.should.autoclose?

    io.autoclose = false
    io_dup = io.dup
    io_dup.should.autoclose?
  end
end

# vim: ts=2 sw=2 et
