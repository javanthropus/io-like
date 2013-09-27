# encoding: UTF-8

require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

ruby_version_is '1.8.7' do
  describe "IO#bytes" do
    before :each do
      @iowrapper = IOSpecs.io_fixture("lines.txt")
    end

    after :each do
      @iowrapper.close unless @iowrapper.closed?
    end

    it "ignores a block" do
      @iowrapper.bytes { raise "oups" }.should be_kind_of(enumerator_class)
    end
  end
end
