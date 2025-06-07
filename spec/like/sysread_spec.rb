# -*- encoding: utf-8 -*-
require_relative '../../spec_helper'

describe "IO::Like#sysread" do
  describe "on write-only stream" do
    before :each do
      @filename = tmp("IO_Like_writeonly_file")
      @writeonly_file = io_like_wrapped_io(File.open(@filename, "w"))
    end

    after :each do
      @writeonly_file.close
      rm_r @filename
    end

    it "raises IOError" do
      lambda { @writeonly_file.sysread(5) }.should raise_error(IOError)
    end
  end
end

# vim: ts=2 sw=2 et
