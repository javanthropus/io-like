# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::BufferedIO#read_buffer_empty?" do
  it "returns true when not in read mode" do
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.read_buffer_empty?.should be_true
    io.write('foo')
    io.read_buffer_empty?.should be_true
  end

  it "returns true when in read mode with an empty buffer" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).and_return(0)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.read(1)
    io.read_buffer_empty?.should be_true
  end

  it "returns false when in read mode with a non-empty buffer" do
    buffer = 'foo'.b
    IO.pipe do |r, w|
      w.write(buffer)
      w.close
      io = IO::LikeHelpers::BufferedIO.new(IO::LikeHelpers::IOWrapper.new(r))
      io.read(1)
      io.read_buffer_empty?.should be_false
    end
  end
end

# vim: ts=2 sw=2 et
