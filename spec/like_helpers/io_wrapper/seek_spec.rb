# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::IOWrapper#seek" do
  before :each do
    @name = tmp('io_wrapper_seek.txt')
    touch @name
    @io = File.open(@name)
  end

  after :each do
    @io.close
    rm_r @name
  end

  it "delegates to its delegate and returns the updated file position" do
    io = IO::LikeHelpers::IOWrapper.new(@io)
    io.seek(1, IO::SEEK_CUR).should == 1
    @io.pos.should == 1
  end

  it "defaults the starting point to be absolute and returns the updated file position" do
    io = IO::LikeHelpers::IOWrapper.new(@io)
    io.seek(5).should == 5
    @io.pos.should == 5
  end

  it "raises Errno::ESPIPE on a pipe" do
    pipe_r, pipe_w = IO.pipe
    pipe_w.close
    io = IO::LikeHelpers::IOWrapper.new(pipe_r)
    -> { io.seek(5) }.should raise_error(Errno::ESPIPE)
  ensure
    pipe_r.close
  end
end

# vim: ts=2 sw=2 et
