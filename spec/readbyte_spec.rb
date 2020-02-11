# encoding: UTF-8

require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

ruby_version_is '1.8.7' do
  describe "IO::Like#readbyte" do
    before :each do
      @original = $KCODE
      $KCODE = "UTF-8"
      @iowrapper = IOSpecs.io_fixture("lines.txt")
    end

    after :each do
      @iowrapper.close unless @iowrapper.closed?
      $KCODE = @original
    end

    it "returns the next byte from the stream" do
      @iowrapper.readline.should == "Voici la ligne une.\n"
      @iowrapper.readbyte.should == 81
      @iowrapper.readbyte.should == 117
      @iowrapper.readbyte.should == 105
      @iowrapper.readbyte.should == 32
      @iowrapper.readbyte.should == 195
    end

    it "raises EOFError when invoked at the end of the stream" do
      # read entire content
      @iowrapper.read
      lambda { @iowrapper.readbyte }.should raise_error(EOFError)
    end

    it "raises EOFError when reaches the end of the stream" do
      lambda { loop { @iowrapper.readbyte } }.should raise_error(EOFError)
    end

    it "raises EOFError on empty stream" do
      tmp_file = tmp('empty.txt')
      File.open(tmp_file, "w+") do |empty|
        lambda { empty.readbyte }.should raise_error(EOFError)
      end
      File.unlink(tmp_file)
    end

    it "raises IOError on closed stream" do
      lambda { IOSpecs.closed_io.readbyte }.should raise_error(IOError)
    end
  end
end
