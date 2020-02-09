# encoding: UTF-8
# encoding: utf-8
require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

ruby_version_is '1.8.7' do
  describe "IO#each_char" do
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

    it "raises IOError on closed stream" do
      lambda { IOSpecs.closed_file.each_char {} }.should raise_error(IOError)
    end

    it "yields each character" do
      @iowrapper.readline.should == "Voici la ligne une.\n"
      chars = []

      @iowrapper.each_char do |c|
        chars << c
        break if chars.length >= 5
      end

      chars.should == ["Q", "u", "i", " ", "è"]
    end

    it "works on empty streams" do
      filename = tmp("IO_Like__each_byte_test")
      File.open(filename, "w+") do |io|
        IOWrapper.open(io) do |iowrapper|
          lambda do
            iowrapper.each_char { |b| raise IOError }
          end.should_not raise_error
        end
      end
      File.unlink(filename) if File.exist?(filename)
    end

    it "returns an Enumerator when passed no block" do
      enum = @iowrapper.each_char
      enum.instance_of?(enumerator_class).should be_true
      enum.each.first(5).should == ["V", "o", "i", "c", "i"]
    end
  end
end
