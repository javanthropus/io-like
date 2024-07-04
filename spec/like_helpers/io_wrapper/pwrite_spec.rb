# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::IOWrapper#pwrite" do
  before :each do
    @filename = tmp('io_wrapper_pwrite')
    @file = File.open(@filename, 'w')
  end

  after :each do
    @file.close
    rm_r(@filename)
  end

  it "delegates to its delegate" do
    buffer = 'foo'.b
    io = IO::LikeHelpers::IOWrapper.new(@file)
    io.pwrite(buffer, 2, length: 1).should == 1
    File.read(@filename).should == "\0\0".b + buffer[0]
  end

  it "defaults the number of bytes to write to the number of bytes in the buffer" do
    buffer = 'foo'.b
    io = IO::LikeHelpers::IOWrapper.new(@file)
    io.pwrite(buffer, 2).should == 3
    File.read(@filename).should == "\0\0".b + buffer
  end
end

# vim: ts=2 sw=2 et
