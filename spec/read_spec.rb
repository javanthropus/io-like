# encoding: UTF-8

require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "IO::Like#read" do
  it "reads all data available before a SystemCallError is raised" do
    io = IOSpecs.io_like_fixture(
      "hello", SystemCallError, SystemCallError, "world"
    )

    io.read.should == "hello"
    lambda { io.read }.should raise_error(SystemCallError)
    io.read.should == "world"
  end

  it "raises IOError on write-only stream" do
    lambda { IOSpecs.writeonly_io { |io| io.read } }.should raise_error(IOError)
  end
end
