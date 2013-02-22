# encoding: UTF-8
require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'
require File.dirname(__FILE__) + '/shared/write'

describe "IO::Like#write" do
  before :each do
    @filename = tmp("IO_Like__write_test")
    @content = "012345678901234567890123456789"
    File.open(@filename, "w") { |f| f.syswrite(@content) }
    @file = File.open(@filename, "r+")
    @iowrapper = IOWrapper.open(@file)
  end

  after :each do
    @iowrapper.close unless @iowrapper.closed?
    @file.close unless @file.closed?
    File.delete(@filename)
  end

  it "does not raise IOError on read-only stream if writing zero bytes" do
    lambda do
      IOSpecs.readable_iowrapper do |iowrapper|
        iowrapper.write("")
      end
    end.should_not raise_error
  end

  it "does not raise IOError on closed stream if writing zero bytes" do
    lambda { IOSpecs.closed_file.write("") }.should_not raise_error
  end
end

describe "IO::Like#write" do
  it_behaves_like :io_like__write, :write
end
