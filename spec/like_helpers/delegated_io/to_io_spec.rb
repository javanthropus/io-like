# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DelegatedIO#to_io" do
  it "delegates to its delegate" do
    obj = mock("io")
    obj.should_receive(:to_io).and_return(:result)
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.to_io.should == :result
  end

  it "raises IOError if the stream is closed" do
    obj = mock("io")
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.close
    -> { io.to_io }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
