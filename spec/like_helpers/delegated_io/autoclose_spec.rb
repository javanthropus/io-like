# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'
require_relative '../../../rubyspec/core/io/fixtures/classes'

describe "IO::LikeHelpers::DelegatedIO#autoclose=" do
  it "returns the argument given" do
    obj = mock("io")
    io = IO::LikeHelpers::DelegatedIO.new(obj)
    io.send(:autoclose=, true).should == true
    io.send(:autoclose=, false).should == false
    io.send(:autoclose=, :foo).should == :foo
  end
end

describe "IO::LikeHelpers::DelegatedIO#autoclose?" do
  before :each do
    obj = mock("io")
    obj.should_receive(:close).and_return(nil)
    @io = IO::LikeHelpers::DelegatedIO.new(obj)
  end

  after :each do
    @io.close
  end

  it "returns the truthiness of #autoclose=" do
    @io.autoclose = true
    @io.autoclose?.should == true

    @io.autoclose = false
    @io.autoclose?.should == false

    @io.autoclose = :foo
    @io.autoclose?.should == true
  end
end

# vim: ts=2 sw=2 et
