# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::IOWrapper#pread" do
  before :each do
    @filename = tmp('io_wrapper_pread')
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
    io.pread(1, 2, buffer: buffer, buffer_offset: 1).should == 1
    buffer.should == 'flo'.b
  end

  it "defaults the buffer to nil and returns bytes read" do
    io = IO::LikeHelpers::IOWrapper.new(@file)
    io.pread(1, 2).should == 'l'.b
  end

  it "raises Argument error when the buffer offset is not a valid buffer index" do
    buffer = 'foo'.b
    io = IO::LikeHelpers::IOWrapper.new(@file)
    -> { io.pread(1, 2, buffer: buffer, buffer_offset: -1) }.should raise_error(ArgumentError)
    -> { io.pread(1, 2, buffer: buffer, buffer_offset: 100) }.should raise_error(ArgumentError)
  end

  it "raises Argument error when the amount to read would not fit into the given buffer" do
    buffer = 'foo'.b
    io = IO::LikeHelpers::IOWrapper.new(@file)
    -> { io.pread(20, 2, buffer: buffer, buffer_offset: 1) }.should raise_error(ArgumentError)
    -> { io.pread(20, 2, buffer: buffer) }.should raise_error(ArgumentError)
  end

  it "raises EOFError at end of file when in blocking mode" do
    io = IO::LikeHelpers::IOWrapper.new(@file)
    io.nonblock?.should be_false
    -> { io.pread(1, 10) }.should raise_error(EOFError)
  end
end

# vim: ts=2 sw=2 et
