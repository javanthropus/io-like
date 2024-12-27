# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DelegatedIO#dup" do
  it "dups the delegate" do
    obj_dup = mock("io_dup")
    # Satisfy the finalizer that will call #close on this object.
    def obj_dup.close; end
    obj_dup.should_receive(:readable?).and_return(true)
    obj = mock("io")
    obj.should_receive(:dup).and_return(obj_dup)
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false).dup
    io.readable?.should be_true
  end

  it "raises IOError when its delegate raises it" do
    obj = mock("io")
    obj.should_receive(:dup).and_raise(IOError.new('closed stream'))
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    -> { io.dup }.should raise_error(IOError, 'closed stream')
  end

  it "raises IOError if the stream is closed" do
    obj = mock("io")
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.close
    -> { io.dup }.should raise_error(IOError, 'closed stream')
  end

  it "sets the autoclose flag on the new stream" do
    obj_dup = mock("io_dup")
    # Satisfy the finalizer that will call #close on this object.
    def obj_dup.close; end
    obj = mock("io")
    obj.should_receive(:dup).and_return(obj_dup).exactly(2)
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)

    io.autoclose = true
    io_dup = io.dup
    io_dup.autoclose?.should be_true

    io.autoclose = false
    io_dup = io.dup
    io_dup.autoclose?.should be_true
  end
end

# vim: ts=2 sw=2 et
