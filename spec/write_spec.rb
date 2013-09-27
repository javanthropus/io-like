# encoding: UTF-8

require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'
require File.dirname(__FILE__) + '/shared/write'

describe "IO::Like#write" do
  it "does not raise IOError on read-only stream if writing zero bytes" do
    lambda { IOSpecs.readonly_io { |io| io.write("") } }.should_not raise_error
  end

  it "does not raise IOError on closed stream if writing zero bytes" do
    lambda { IOSpecs.closed_io.write("") }.should_not raise_error
  end
end

describe "IO::Like#write" do
  it_behaves_like :io_like__write, :write
end
