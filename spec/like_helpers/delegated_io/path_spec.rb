# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DelegatedIO#path" do
  it "delegates to its delegate" do
    obj = mock("io")
    obj.should_receive(:path).and_return("foo")
    io = IO::LikeHelpers::DelegatedIO.new(obj)
    io.path.should == "foo"
  end

  it "raises IOError if the stream is closed" do
    obj = mock("io")
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.close
    -> { io.path }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
