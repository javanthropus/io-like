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

  it "delegates to its delegate" do
    buffer = 'foo'.b
    io = IO::LikeHelpers::IOWrapper.new(@file)
    io.pread(1, 2, buffer: buffer).should == 1
    buffer[0].should == 'l'.b
    buffer[1].should == 'o'.b
  end

  it "defaults the buffer to nil and returns bytes read" do
    io = IO::LikeHelpers::IOWrapper.new(@file)
    io.pread(1, 2).should == 'l'.b
  end

  it "raises EOFError at end of file when in blocking mode" do
    io = IO::LikeHelpers::IOWrapper.new(@file)
    io.nonblock?.should be_false
    -> { io.pread(1, 10) }.should raise_error(EOFError)
  end
end

# vim: ts=2 sw=2 et
