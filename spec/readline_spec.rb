# encoding: UTF-8

require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "IO::Like#readline" do
  # TODO:
  # gets and readline really should share specs, except for handling EOF.
  it "reads and returns all data available before a SystemCallError is raised when the separator is nil" do
    io = IOSpecs.io_like_fixture(
      "hello", SystemCallError, SystemCallError, "world"
    )

    io.readline(nil).should == "hello"
    lambda { io.readline("") }.should raise_error(SystemCallError)
    io.readline(nil).should == "world"
  end
end
