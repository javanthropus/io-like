# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DelegatedIO#writable?" do
  it "delegates to its delegate exactly once" do
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    io = IO::LikeHelpers::DelegatedIO.new(obj)
    io.writable?.should be_true
    io.writable?.should be_true
  end

  it "returns false if the stream is closed" do
    obj = mock("io")
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.close
    io.writable?.should be_false
  end
end

# vim: ts=2 sw=2 et
