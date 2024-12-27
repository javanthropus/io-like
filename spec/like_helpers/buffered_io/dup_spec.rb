# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::BufferedIO#dup" do
  it "dups the delegate" do
    obj_dup = mock("io_dup")
    # Satisfy the finalizer that will call #close on this object.
    def obj_dup.close; end
    obj_dup.should_receive(:readable?).and_return(true)
    obj = mock("io")
    obj.should_receive(:dup).and_return(obj_dup)
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false).dup
    io.readable?.should be_true
  end

  it "dups the internal buffer" do
    buffer = 'foo'.b
    obj_dup = mock("io_dup")
    # Satisfy the finalizer that will call #close on this object.
    def obj_dup.close; end
    obj_dup.should_receive(:write).with(buffer).and_return(buffer.size)
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:dup).and_return(obj_dup)
    obj.should_receive(:write).with(buffer).and_return(buffer.size)
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
    io.write(buffer)
    io_dup = io.dup

    io.flush
    io_dup.flush
  end

  it "raises IOError if the stream is closed" do
    obj = mock("io")
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
    io.close
    -> { io.dup }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
