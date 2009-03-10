require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "IO::Like#readline" do
  before :each do
    testfile = File.dirname(__FILE__) + '/fixtures/gets.txt'
    @io = File.open(testfile, 'r')
    @iowrapper = IOWrapper.open(@io)
  end

  after :each do
    @iowrapper.close unless @iowrapper.closed?
    @io.close unless @io.closed?
  end

  it "returns the next line on the stream" do
    @iowrapper.readline.should == "Voici la ligne une.\n"
    @iowrapper.readline.should == "Qui è la linea due.\n"
  end

  it "goes back to first position after a rewind" do
    @iowrapper.readline.should == "Voici la ligne une.\n"
    @iowrapper.rewind
    @iowrapper.readline.should == "Voici la ligne une.\n"
  end

  it "is modified by the cursor position" do
    @iowrapper.seek(1)
    @iowrapper.readline.should == "oici la ligne une.\n"
  end

  it "raises EOFError on end of stream" do
    lambda { loop { @iowrapper.readline } }.should raise_error(EOFError)
  end

  it "raises IOError on closed stream" do
    lambda { IOSpecs.closed_file.readline }.should raise_error(IOError)
  end
end
