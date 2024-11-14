# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::BufferedIO#seek" do
  it "delegates to its delegate" do
    obj = mock("io")
    obj.should_receive(:seek).with(1, :CUR).and_return(:result)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.seek(1, :CUR).should == :result
  end

  it "defaults the starting point to be absolute" do
    obj = mock("io")
    obj.should_receive(:seek).with(1, IO::SEEK_SET).and_return(:result)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.seek(1).should == :result
  end

  it "flushes the internal buffer when in write mode" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:write).with(buffer).and_return(3)
    obj.should_receive(:seek).with(1, IO::SEEK_SET).and_return(1)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.write(buffer)
    io.seek(1).should == 1
  end

  it "returns a Symbol when the flush operation does so" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:write).with(buffer).and_return(:wait_writable)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.write(buffer)
    io.seek(1).should == :wait_writable
  end

  it "flushes the internal read buffer when not performing a seek relative to the current location" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).and_return(3).exactly(2)
    obj.should_receive(:seek).with(0, IO::SEEK_SET).and_return(0)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.read(1, buffer: buffer).should == 1
    io.seek(0, IO::SEEK_SET).should == 0
    io.read(1, buffer: buffer).should == 1
  end

  it "accounts for the internal read buffer content when performing a seek relative to the current location" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).and_return(3)
    obj.should_receive(:seek).with(-1, IO::SEEK_CUR).and_return(2)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.read(1, buffer: buffer).should == 1
    io.seek(1, IO::SEEK_CUR).should == 2
  end

  it "ignores bytes pushed into the buffer via #unread when performing seek from the start of the stream" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).and_return(3)
    obj.should_receive(:seek).with(1, IO::SEEK_SET).and_return(1)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.read(1, buffer: buffer).should == 1
    io.unread('bar').should be_nil
    io.seek(1, IO::SEEK_SET).should == 1
  end

  it "ignores bytes pushed into the buffer via #unread when performing seek from the end of the stream" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).and_return(3)
    obj.should_receive(:seek).with(-1, IO::SEEK_END).and_return(1)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.read(1, buffer: buffer).should == 1
    io.unread('bar').should be_nil
    io.seek(-1, IO::SEEK_END).should == 1
  end

  it "ignores bytes pushed into the buffer via #unread when performing seek from the current position of the stream" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).and_return(3)
    obj.should_receive(:seek).with(-3, IO::SEEK_CUR).and_return(0)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.read(1, buffer: buffer).should == 1
    io.unread('bar').should be_nil
    io.seek(-1, IO::SEEK_CUR).should == 0
  end

  it "raises IOError if the stream is closed" do
    obj = mock("io")
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
    io.close
    -> { io.seek(1) }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
