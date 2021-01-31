# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DelegatedIO#close" do
  it "delegates to its delegate when #autoclose? is true" do
    obj = mock("io")
    obj.should_receive(:close).and_return(nil)
    io = IO::LikeHelpers::DelegatedIO.new(obj)
    io.close.should be_nil
  end

  it "short circuits after the first call" do
    obj = mock("io")
    obj.should_receive(:close).and_return(nil)
    io = IO::LikeHelpers::DelegatedIO.new(obj)
    io.close.should be_nil
    io.close.should be_nil
  end

  it "does not delegate to its delegate when #autoclose? is false" do
    obj = mock("io")
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.close.should be_nil
  end

  it "returns a Symbol if its delegate does so" do
    obj = mock("io")
    obj.should_receive(:close).and_return(:wait_readable)
    io = IO::LikeHelpers::DelegatedIO.new(obj)
    io.close.should == :wait_readable
  end
end

# vim: ts=2 sw=2 et
