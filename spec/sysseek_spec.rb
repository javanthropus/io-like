# encoding: UTF-8
require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "IO::Like#sysseek on a file" do
  # TODO: This should be made more generic with seek spec
  before :each do
    @iowrapper = IOSpecs.io_fixture("lines.txt")
  end

  after :each do
    @iowrapper.close unless @iowrapper.closed?
  end

  it "warns if called immediately after a buffered IO#write" do
    begin
      # copy contents to a separate file
      tmpfile = tmp("tmp_IO_sysseek")
      wrapper = File.open(tmpfile,"w")
      wrapper.write(@iowrapper.read)
      wrapper.seek(0, File::SEEK_SET)
      wrapper.write("abcde")
      lambda { wrapper.sysseek(10) }.should complain(/sysseek/)
    ensure
      wrapper.close
      rm_r tmpfile
    end
  end

end
