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

    it "ignores a block" do
      @iowrapper.bytes { raise "oups" }.should be_kind_of(enumerator_class)
    end

  end
end
