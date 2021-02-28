# -*- encoding: utf-8 -*-
require_relative '../../spec_helper'

describe "IO::Like#print" do
  before :each do
    @old_record_separator = $\
    @old_field_separator = $,
    @filename = tmp('IO_Like__print_test')
    @io = io_like_wrapped_io(File.open(@filename, 'w'))
    @io.sync = true
  end

  after :each do
    $\ = @old_record_separator
    $, = @old_field_separator
    @io.close
    rm_r @filename
  end

  it "returns nil" do
    @io.print('hello').should be_nil
  end

  it "writes nil arguments as \"nil\"" do
    @io.print(nil)
    File.read(@filename).should == "nil"
  end

  it "does not append anything to the output when $\\ is nil" do
    $\ = nil
    data = 'abcdefgh9876'
    @io.print(data)
    File.read(@filename).should == data
  end

  it "writes $, between arguments" do
    $, = '->'
    data1 = 'abcdefgh9876'
    data2 = '12345678zyxw'
    @io.print(data1, data2)
    File.read(@filename).should == "#{data1}#{$,}#{data2}"
  end

  it "does not write anything between arguments when $, is nil" do
    $, = nil
    data1 = 'abcdefgh9876'
    data2 = '12345678zyxw'
    @io.print(data1, data2)
    File.read(@filename).should == "#{data1}#{data2}"
  end
end

# vim: ts=2 sw=2 et
