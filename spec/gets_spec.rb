# encoding: UTF-8
require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "IO::Like#gets" do

  it "reads and returns all data available before a SystemCallError is raised when the separator is nil" do
    file = File.open(IOSpecs.gets_fixtures)
    # Overrride file.sysread to raise SystemCallError every other time it's
    # called.
    class << file
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

    ReadableIOWrapper.open(file) do |iowrapper|
      lambda { iowrapper.gets(nil) }.should raise_error(SystemCallError)
      iowrapper.gets(nil).should == IOSpecs.lines.join('')
    end
    file.close
  end
end
