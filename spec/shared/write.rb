# encoding: UTF-8
require File.dirname(__FILE__) + '/../fixtures/classes'

describe :io_like__write, :shared => true do
 
  before :each do
    @filename = tmp("IO_Like__shared_write_test")
    @content = "012345678901234567890123456789"
    File.open(@filename, "w") { |f| f.write(@content) }
    @file = File.open(@filename, "r+")
    @iowrapper = IOWrapper.open(@file)
  end

  after :each do
    @iowrapper.close unless @iowrapper.closed?
    @file.close unless @file.closed?
    File.delete(@filename)
  end

  it "raises IOError unless #writable?"

  it "raises IOError on read-only stream if writing more than zero bytes" do
    lambda do
      IOSpecs.readable_iowrapper do |iowrapper|
        iowrapper.send(@method, "abcde")
      end
    end.should raise_error(IOError)
  end

  it "raises IOError on closed stream if writing more than zero bytes" do
    lambda do
      IOSpecs.closed_file.send(@method, "abcde")
    end.should raise_error(IOError)
  end
end
