# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::BufferedIO#unbuffered_write" do
  it "delegates to its delegate" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:write).with(buffer, length: buffer.size).and_return(buffer.size)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.unbuffered_write(buffer, length: buffer.size).should == buffer.size
  end

  it "defaults the number of bytes to write to the number of bytes in the buffer" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:write).with(buffer, length: buffer.size).and_return(buffer.size)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.unbuffered_write(buffer).should == buffer.size
  end

  it "bypasses the internal write buffer" do
    buffer1 = 'foo'.b
    buffer2 = 'bar'.b
    IO.pipe do |r, w|
      io = IO::LikeHelpers::BufferedIO.new(IO::LikeHelpers::IOWrapper.new(w))
      io.write(buffer1).should == buffer1.size
      io.unbuffered_write(buffer2).should == buffer2.size
      io.close
      r.read == buffer2 + buffer1
    end
  end

  it "does not modify the internal read buffer" do
    buffer1 = 'foo'.b
    buffer2 = 'bar'.b
    filename = tmp('buffered_io_unbuffered_write')
    begin
      File.write(filename, buffer1)
      File.open(filename, 'r+') do |f|
        io = IO::LikeHelpers::BufferedIO.new(IO::LikeHelpers::IOWrapper.new(f))
        io.read(1) == buffer1[0]
        io.unbuffered_write(buffer2).should == buffer2.size
        io.read(2) == buffer1[2, 2]
      end
    ensure
      rm_r(filename)
    end
  end

  it "raises IOError if its delegate is not writable" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(false)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    -> { io.unbuffered_write(buffer) }.should raise_error(IOError, 'not opened for writing')
  end

  it "raises IOError if the stream is closed" do
    buffer = 'foo'.b
    obj = mock("io")
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
    io.close
    -> { io.unbuffered_write(buffer) }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
