# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DelegatedIO#fdatasync" do
  it "delegates to its delegate" do
    obj = mock("io")
    obj.should_receive(:fdatasync).and_return(nil)
    io = IO::LikeHelpers::DelegatedIO.new(obj)
    io.fdatasync.should be_nil
  end

  it "raises IOError if the stream is closed" do
    obj = mock("io")
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.close
    -> { io.fdatasync }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et