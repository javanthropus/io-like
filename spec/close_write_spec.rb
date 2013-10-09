# encoding: UTF-8

require File.expand_path('../../spec_helper', __FILE__)
require File.expand_path('../fixtures/classes', __FILE__)

describe "IO::Like#close_write" do
  before :each do
    @path = tmp('io.close.txt')
    @io = File.open @path, 'w'
  end

  after :each do
    @io.close unless @io.closed?
    rm_r @path
  end

  it "raises an IOError on subsequent invocations" do
    @io.close_write

    lambda { @io.close_write }.should raise_error(IOError)
  end

  it "flushes and closes the write stream" do
    begin
      io_r, io_w = IO.pipe

      io_w.puts '12345'

      io_w.close_write

      io_r.read.should == "12345\n"
    ensure
      io_r.close unless io_r.closed?
      io_w.close unless io_w.closed?
    end
  end

  it "raises IOError on closed stream" do
    @io.close

    lambda { @io.close_write }.should raise_error(IOError)
  end
end
