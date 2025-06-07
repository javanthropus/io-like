# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::IOWrapper#write" do
  before :each do
    @filename = tmp('io_wrapper_write')
    @file = File.open(@filename, 'w')
  end

  after :each do
    @file.close
    rm_r(@filename)
  end

  it "delegates to its delegate" do
    buffer = 'foo'.b
    io = IO::LikeHelpers::IOWrapper.new(@file)
    io.write(buffer, length: 1).should == 1
    File.read(@filename).should == buffer[0]
  end

  it "defaults the number of bytes to write to the number of bytes in the buffer" do
    buffer = 'foo'.b
    io = IO::LikeHelpers::IOWrapper.new(@file)
    io.write(buffer).should == 3
    File.read(@filename).should == buffer
  end

  it "returns a Symbol when the delegate can take no more data in nonblocking mode" do
    IO.pipe do |pipe_r, pipe_w|
      io = IO::LikeHelpers::IOWrapper.new(pipe_w)
      io.nonblock = true
      io.nonblock?.should be_true
      io.write('a' * 1_000_000).should < 1_000_000 # Fill the pipe
      io.write('a').should == :wait_writable
    end
  end

  it "writes to the delegate in nonblocking mode" do
    IO.pipe do |pipe_r, pipe_w|
      io = IO::LikeHelpers::IOWrapper.new(pipe_w)
      io.nonblock = true
      io.nonblock?.should be_true
      io.write('a').should == 1
    end
  end
end

# vim: ts=2 sw=2 et
