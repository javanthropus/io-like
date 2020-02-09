# encoding: UTF-8
# encoding: utf-8
require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

ruby_version_is '1.8.7' do
  describe "IO#getbyte" do
    before :each do
      @original = $KCODE
      $KCODE = "UTF-8"
      @file_name = File.dirname(__FILE__) + '/fixtures/readlines.txt'
      @file = File.open(@file_name, 'r')
      @iowrapper = ReadableIOWrapper.open(@file)
    end

    after :each do
      @iowrapper.close unless @iowrapper.closed?
      @file.close unless @file.closed?
      $KCODE = @original
    end

    it "returns the next byte from the stream" do
      @iowrapper.readline.should == "Voici la ligne une.\n"
      @iowrapper.getbyte.should == 81
      @iowrapper.getbyte.should == 117
      @iowrapper.getbyte.should == 105
      @iowrapper.getbyte.should == 32
      @iowrapper.getbyte.should == 195
    end

    it "returns nil when invoked at the end of the stream" do
      # read entire content
      @iowrapper.read
      @iowrapper.getbyte.should == nil
    end

    it "returns nil on empty stream" do
      File.open(tmp('empty.txt'), "w+") do |empty|
        IOWrapper.open(empty) do |iowrapper|
          iowrapper.getbyte.should == nil
        end
      end
      File.unlink(tmp("empty.txt"))
    end

    it "raises IOError on closed stream" do
      lambda { IOSpecs.closed_file.getbyte }.should raise_error(IOError)
    end
  end
end
