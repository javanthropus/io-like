# -*- encoding: utf-8 -*-

describe :io_like__write, :shared => true do
  describe "on read-only stream" do
    before :each do
      @filename = tmp("IO_Like_readonly_file")
      File.write(@filename, "hello")
      @readonly_file = io_like_wrapped_io(File.open(@filename, "r"))
    end

    after :each do
      @readonly_file.close
      rm_r @filename
    end

    it "raises IOError if writing more than zero bytes" do
      lambda do
        @readonly_file.send(@method, "abcde")
      end.should raise_error(IOError)
    end
  end
end

# vim: ts=2 sw=2 et
