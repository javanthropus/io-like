# -*- encoding: utf-8 -*-
require_relative '../../spec_helper'
require_relative '../../rubyspec/core/io/fixtures/classes'

describe "IO::Like#rewind" do
  before :each do
    @io = IOSpecs.io_fixture "lines.txt"
  end

  after :each do
    @io.close
  end

  it "should return 0" do
    @io.rewind.should == 0
  end
end

# vim: ts=2 sw=2 et
