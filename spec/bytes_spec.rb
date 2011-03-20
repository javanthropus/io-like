# encoding: UTF-8
# encoding: utf-8
require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

ruby_version_is '1.8.7' do
  describe "IO#bytes" do
    before :each do
      @original = $KCODE
      $KCODE = "UTF-8"
      @io = File.open(IOSpecs.gets_fixtures)
      @iowrapper = ReadableIOWrapper.open(@io)
    end

    after :each do
      @iowrapper.close unless @iowrapper.closed?
      @io.close unless @io.closed?
      $KCODE = @original
    end

    it "returns an enumerator of the next bytes from the stream" do
      enum = @iowrapper.bytes
      enum.should be_kind_of(enumerator_class)
      @iowrapper.readline.should == "Voici la ligne une.\n"
      enum.first(5).should == [81, 117, 105, 32, 195]
    end

    it "ignores a block" do
      @iowrapper.bytes { raise "oups" }.should be_kind_of(enumerator_class)
    end

    it "raises IOError on closed stream" do
      enum = IOSpecs.closed_file.bytes
      lambda { enum.first }.should raise_error(IOError)
      enum = @iowrapper.bytes
      enum.first.should == 86
      @iowrapper.close
      lambda { enum.first }.should raise_error(IOError)
    end
  end
end
