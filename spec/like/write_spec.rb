# encoding: UTF-8

require_relative '../../spec_helper'
require_relative '../../rubyspec/core/io/fixtures/classes'
require_relative 'shared/write'

describe "IO::Like#write" do
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

    it "returns 0 when writing zero bytes" do
      @readonly_file.write("").should == 0
    end
  end

  describe "on a closed stream" do
    before :each do
      @filename = tmp("IO_Like_writeonly_file")
      File.write(@filename, "hello")
      @writeonly_file = io_like_wrapped_io(File.open(@filename, "w"))
      @writeonly_file.close
    end

    after :each do
      @writeonly_file.close
      rm_r @filename
    end

    it "returns 0 when writing zero bytes" do
      @writeonly_file.write("").should == 0
    end
  end
end

describe "IO::Like#write" do
  it_behaves_like :io_like__write, :write
end

# vim: ts=2 sw=2 et
