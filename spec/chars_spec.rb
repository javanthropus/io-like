# encoding: utf-8
require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

ruby_version_is '1.8.7' do
  describe "IO#chars" do
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

    it "returns an enumerator of the next chars from the stream" do
      enum = @iowrapper.chars
      enum.should be_kind_of(enumerator_class)
      @iowrapper.readline.should == "Voici la ligne une.\n"
      enum.first(5).should == ["Q", "u", "i", " ", "è"]
    end

    ruby_version_is '1.9' do
      it "ignores a block" do
        @iowrapper.chars{ raise "oups" }.should be_kind_of(enumerator_class)
      end
    end

    it "raises IOError on closed stream" do
      enum = IOSpecs.closed_file.chars
      lambda { enum.first }.should raise_error(IOError)
      enum = @iowrapper.chars
      enum.first.should == "V"
      @iowrapper.close
      lambda { enum.first }.should raise_error(IOError)
    end
  end
end
