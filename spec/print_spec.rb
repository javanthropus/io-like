# encoding: UTF-8
require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "IO::Like#print" do
  before :each do
    @old_record_separator = $\
    @old_field_separator = $,
    @filename = tmp('IO_Like__print_test')
    @iowrapper = File.open(@filename, 'w')
    @iowrapper.sync=true
  end

  after :each do
    $\ = @old_record_separator
    $, = @old_field_separator
    @iowrapper.close unless @iowrapper.closed?
    rm_r @filename
  end

  it "returns nil" do
    @iowrapper.print('hello').should == nil
  end

  it "writes nil arguments as \"nil\"" do
    @iowrapper.print(nil)
    File.read(@filename).should == "nil"
  end

  it "does not append anything to the output when $\\ is nil" do
    $\ = nil
    data = 'abcdefgh9876'
    @iowrapper.print(data)
    File.read(@filename).should == data
  end

  it "writes $, between arguments" do
    $, = '->'
    data1 = 'abcdefgh9876'
    data2 = '12345678zyxw'
    @iowrapper.print(data1, data2)
    File.read(@filename).should == "#{data1}#{$,}#{data2}"
  end

  it "does not write anything between arguments when $, is nil" do
    $, = nil
    data1 = 'abcdefgh9876'
    data2 = '12345678zyxw'
    @iowrapper.print(data1, data2)
    File.read(@filename).should == "#{data1}#{data2}"
  end

end
