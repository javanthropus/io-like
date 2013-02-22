# encoding: UTF-8
require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "IO::Like#read" do
  before :each do
    @filename = tmp('IO_Like__read_test')
    @contents = "1234567890"
    File.open(@filename, "w") { |io| io.write(@contents) }

    @file = File.open(@filename, "r+")
    @iowrapper = IOWrapper.open(@file)
  end

  after :each do
    @iowrapper.close unless @iowrapper.closed?
    @file.close unless @file.closed?
    File.delete(@filename) if File.exists?(@filename)
  end

  it "reads all data available before a SystemCallError is raised" do
    # Overrride @file.sysread to raise SystemCallError every other time it's
    # called.
    class << @file
      alias :sysread_orig :sysread
      def sysread(length)
        if @error_raised then
          @error_raised = false
          sysread_orig(length)
        else
          @error_raised = true
          raise SystemCallError, 'Test Error'
        end
      end
    end

    lambda { @iowrapper.read }.should raise_error(SystemCallError)
    @iowrapper.read.should == @contents
  end

  it "raises IOError on write-only stream" do
    lambda { IOSpecs.writable_iowrapper.read }.should raise_error(IOError)
  end

end
