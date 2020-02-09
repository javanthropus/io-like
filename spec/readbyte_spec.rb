# encoding: UTF-8
require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

ruby_version_is '1.8.7' do
  describe "IO::Like#readbyte" do
    before :each do
      @original = $KCODE
      $KCODE = "UTF-8"
      @file_name = File.dirname(__FILE__) + '/fixtures/readlines.txt'
      @io = File.open(@file_name, 'r')
      @iowrapper = IOWrapper.open(@io)
    end

    after :each do
      @iowrapper.close unless @iowrapper.closed?
      @io.close unless @io.closed?
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
      @io.read
      lambda { @io.readbyte }.should raise_error(EOFError)
    end

    it "raises EOFError when reaches the end of the stream" do
      lambda { loop { @io.readbyte } }.should raise_error(EOFError)
    end

    it "raises EOFError on empty stream" do
      File.open(tmp('empty.txt'), "w+") do |empty|
        IOWrapper.open(empty) do |iowrapper|
          lambda { iowrapper.readbyte }.should raise_error(EOFError)
        end
      end
      File.unlink(tmp("empty.txt"))
    end

    it "raises IOError on closed stream" do
      lambda { IOSpecs.closed_file.readbyte }.should raise_error(IOError)
    end
  end
end
