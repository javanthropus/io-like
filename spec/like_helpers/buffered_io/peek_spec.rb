# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::BufferedIO#peek" do
  before :each do
    @data = 'foo'.b * 100
    @tmpfile = tmp("tmp_BufferedIO_peek")
    tmpio = File.open(@tmpfile, 'w+b')
    tmpio.write(@data)
    tmpio.rewind
    @delegate = IO::LikeHelpers::IOWrapper.new(tmpio)
  end

  after :each do
    @delegate.close
    rm_r @tmpfile
  end

  it "returns a buffer with all available content" do
    io = IO::LikeHelpers::BufferedIO.new(@delegate)
    io.refill
    io.peek.should == @data
  end

  it "returns a buffer with the requested amount of content" do
    io = IO::LikeHelpers::BufferedIO.new(@delegate)
    io.refill
    io.peek(1).should == @data[0]
  end

  it "returns a buffer with no more than the available content" do
    io = IO::LikeHelpers::BufferedIO.new(@delegate)
    io.refill
    io.peek(1000).should == @data
  end

  it "does not flush the write buffer when in write mode" do
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:readable?).and_return(true)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.write('bar'.b)
    io.peek(1).should == ''.b
  end

  it "raises ArgumentError if length is invalid" do
    io = IO::LikeHelpers::BufferedIO.new(@delegate)
    -> { io.peek(-1) }.should raise_error(ArgumentError)
  end

  it "raises IOError if its delegate is not readable" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(false)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    -> { io.peek(1) }.should raise_error(IOError, 'not opened for reading')
  end

  it "raises IOError if the stream is closed" do
    io = IO::LikeHelpers::BufferedIO.new(@delegate)
    io.close
    -> { io.peek(1) }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
