# encoding: UTF-8

require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "IO::Like#gets" do
  it "reads and returns all data available before a SystemCallError is raised when the separator is nil" do
    io = IOSpecs.io_like_fixture(
      "hello", SystemCallError, SystemCallError, "world"
    )
    io.gets(nil).should == "hello"
    lambda { io.gets(nil) }.should raise_error(SystemCallError)
    io.gets(nil).should == "world"
  end
end
