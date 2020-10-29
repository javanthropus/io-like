# encoding: UTF-8

require_relative '../../spec_helper'
require_relative '../../rubyspec/core/io/fixtures/classes'
require_relative 'shared/write'

describe "IO::Like#write" do
  describe "on read-only stream" do
    before :each do
      @filename = tmp("IO_Like_readonly_file")
      File.write(@filename, "hello")
      @readonly_file = File.open(@filename, "r")
    end

    after :each do
      @readonly_file.close
      rm_r @filename
    end

    it "returns 0 when writing zero bytes" do
      @readonly_file.write("").should == 0
    end
  end

  it "returns 0 when writing zero bytes" do
    IOSpecs.closed_io.write("").should == 0
  end
end

describe "IO::Like#write" do
  it_behaves_like :io_like__write, :write
end

# vim: ts=2 sw=2 et
