# encoding: UTF-8

require File.expand_path('../../spec_helper', __FILE__)
require File.expand_path('../fixtures/classes', __FILE__)

describe "IO::Like#close_read" do

  before :each do
    @path = tmp('io.close.txt')
    touch @path
    @io = File.open @path
  end

  after :each do
    @io.close unless @io.closed?
    rm_r @path
  end

  it "raises an IOError on subsequent invocations" do
    @io.close_read

    lambda { @io.close_read }.should raise_error(IOError)
  end

  it "raises IOError on closed stream" do
    @io.close

    lambda { @io.close_read }.should raise_error(IOError)
  end

end

