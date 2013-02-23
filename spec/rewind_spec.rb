# encoding: UTF-8
require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "IO::Like#rewind" do
  before :each do
    @iowrapper = File.open(File.dirname(__FILE__) + '/fixtures/readlines.txt', 'r')
  end

  after :each do
    @iowrapper.close unless @iowrapper.closed?
  end

  it "should return 0" do
    @iowrapper.rewind.should == 0
  end

  it "works on write-only streams" do
    file = tmp('IO_Like__rewind.test')
    File.open(file, 'w') do |io|
      io.write('test1')
      io.rewind.should == 0
      io.write('test2')
    end
    File.read(file).should == 'test2'
    File.delete(file)
  end

end
