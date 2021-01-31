# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::BufferedIO#write_buffer_empty?" do
  it "returns true when not in write mode" do
    buffer = 'foo'.b
    IO.pipe do |r, w|
      w.write(buffer)
      w.close
      io = IO::LikeHelpers::BufferedIO.new(IO::LikeHelpers::IOWrapper.new(r))
      io.read(1)
      io.write_buffer_empty?.should be_true
    end
  end

  it "returns true when in write mode with an empty buffer" do
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:write).and_return(3)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.write('foo'.b)
    io.flush
    io.write_buffer_empty?.should be_true
  end

  it "returns false when in write mode with a non-empty buffer" do
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.write('foo'.b)
    io.write_buffer_empty?.should be_false
  end
end

# vim: ts=2 sw=2 et
