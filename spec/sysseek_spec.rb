# encoding: UTF-8
require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'

describe "IO::Like#sysseek on a file" do
  # TODO: This should be made more generic with seek spec
  before :each do
    @file = File.open(File.dirname(__FILE__) + '/fixtures/readlines.txt', 'r')
    @iowrapper = IOWrapper.open(@file)
  end

  after :each do
    @iowrapper.close unless @iowrapper.closed?
    @file.close unless @file.closed?
  end

  it "warns if called immediately after a buffered IO#write" do
    begin
      # copy contents to a separate file
      tmpfile = File.open(tmp("tmp_IO_sysseek"), "w")
      wrapper = IOWrapper.open(tmpfile)
      wrapper.write(@iowrapper.read)
      wrapper.seek(0, File::SEEK_SET)

      wrapper.write("abcde")
      lambda { wrapper.sysseek(10) }.should complain(/sysseek/)
    ensure
      wrapper.close
      File.unlink(tmpfile.path)
    end
  end

end
