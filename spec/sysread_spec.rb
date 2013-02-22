# encoding: UTF-8
require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "IO::Like#sysread on a file" do

  it "raises IOError on write-only stream" do
    lambda { IOSpecs.writable_iowrapper.sysread(5) }.should raise_error(IOError)
  end

end
