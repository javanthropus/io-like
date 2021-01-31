# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::IOWrapper#fcntl" do
  before :each do
    @name = tmp('io_wrapper_fcntl.txt')
    touch @name
    @io = File.open(@name)
  end

  after :each do
    @io.close
    rm_r @name
  end

  it "delegates to its delegate" do
    io = IO::LikeHelpers::IOWrapper.new(@io)
    (io.fcntl(Fcntl::F_GETFL) & Fcntl::O_ACCMODE).should == Fcntl::O_RDONLY
  end
end

# vim: ts=2 sw=2 et
