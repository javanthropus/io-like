# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::BufferedIO#dup" do
  it "dups the delegate" do
    obj_dup = mock("io_dup")
    obj_dup.should_receive(:readable?).and_return(true)
    obj_dup.should_receive(:close).and_return(nil)
    obj = mock("io")
    obj.should_receive(:dup).and_return(obj_dup)
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false).dup

    io.readable?.should be_true

    io.close
  end

  it "dups the internal buffer" do
    buffer = 'foo'.b
    obj_dup = mock("io_dup")
    obj_dup.should_receive(:write).with(buffer).and_return(buffer.size)
    obj_dup.should_receive(:close).and_return(nil)
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:dup).and_return(obj_dup)
    obj.should_receive(:write).with(buffer).and_return(buffer.size)
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
    io.write(buffer)
    io_dup = io.dup

    io.flush
    io_dup.flush

    io_dup.close
  end

  it "raises IOError if the stream is closed" do
    obj = mock("io")
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
    io.close
    -> { io.dup }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
