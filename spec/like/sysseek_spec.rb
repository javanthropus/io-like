# -*- encoding: utf-8 -*-
require_relative '../../spec_helper'

describe "IO::Like#sysseek on a file" do
  it "warns if called immediately after a buffered IO#write" do
    begin
      # copy contents to a separate file
      tmpfile = tmp("tmp_IO_sysseek")
      wrapper = io_like_wrapped_io(File.open(tmpfile, "w"))
      wrapper.write("abcde")
      lambda { wrapper.sysseek(10) }.should complain(/sysseek/)
    ensure
      wrapper.close
      rm_r tmpfile
    end
  end
end

# vim: ts=2 sw=2 et
