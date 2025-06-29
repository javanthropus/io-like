# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::IOWrapper#read" do
  before :each do
    @filename = tmp('io_wrapper_read')
    File.write(@filename, 'hello')
    @file = File.open(@filename)
  end

  after :each do
    @file.close
    rm_r(@filename)
  end

  it "delegates to its delegate and returns count of bytes read" do
    buffer = 'foo'.b
    io = IO::LikeHelpers::IOWrapper.new(@file)
    io.read(1, buffer: buffer, buffer_offset: 1).should == 1
    buffer.should == 'fho'.b
  end

  it "defaults the buffer to nil and returns bytes read" do
    io = IO::LikeHelpers::IOWrapper.new(@file)
    io.read(1).should == 'h'
  end

  it "raises Argument error when the buffer offset is not a valid buffer index" do
    buffer = 'foo'.b
    io = IO::LikeHelpers::IOWrapper.new(@file)
    -> { io.read(1, buffer: buffer, buffer_offset: -1) }.should raise_error(ArgumentError)
    -> { io.read(1, buffer: buffer, buffer_offset: 100) }.should raise_error(ArgumentError)
  end

  it "raises Argument error when the amount to read would not fit into the given buffer" do
    buffer = 'foo'.b
    io = IO::LikeHelpers::IOWrapper.new(@file)
    -> { io.read(20, buffer: buffer, buffer_offset: 1) }.should raise_error(ArgumentError)
    -> { io.read(20, buffer: buffer) }.should raise_error(ArgumentError)
  end

  it "raises EOFError at end of file when in blocking mode" do
    io = IO::LikeHelpers::IOWrapper.new(@file)
    io.nonblock?.should be_false
    io.read(5).should == 'hello'
    -> { io.read(1) }.should raise_error(EOFError)
  end

  it "raises EOFError at end of file when in nonblocking mode" do
    IO.pipe do |pipe_r, pipe_w|
      pipe_w.write('hello')
      pipe_w.close

      io = IO::LikeHelpers::IOWrapper.new(pipe_r)
      io.nonblock = true
      io.nonblock?.should be_true
      io.read(5).should == 'hello'
      -> { io.read(1) }.should raise_error(EOFError)
    end
  end

  it "returns a Symbol when waiting for data in nonblocking mode" do
    IO.pipe do |pipe_r, pipe_w|
      pipe_w.write('hello')

      io = IO::LikeHelpers::IOWrapper.new(pipe_r)
      io.nonblock = true
      io.nonblock?.should be_true
      io.read(5).should == 'hello'
      io.read(1).should == :wait_readable
    end
  end
end

# vim: ts=2 sw=2 et
