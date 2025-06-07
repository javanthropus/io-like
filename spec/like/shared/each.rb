# -*- encoding: utf-8 -*-

describe :io_like__each, :shared => true do
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
      lambda { @writeonly_file.send(@method) {} }.should raise_error(IOError)
    end
  end
end

# vim: ts=2 sw=2 et
