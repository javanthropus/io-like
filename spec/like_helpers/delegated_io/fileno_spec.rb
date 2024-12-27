# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DelegatedIO#fileno" do
  it "delegates to its delegate" do
    obj = mock("io")
    obj.should_receive(:fileno).and_return(nil)
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.fileno.should be_nil
  end

  it "raises IOError when its delegate raises it" do
    obj = mock("io")
    obj.should_receive(:fileno).and_raise(IOError.new('closed stream'))
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    -> { io.fileno }.should raise_error(IOError, 'closed stream')
  end

  it "raises IOError if the stream is closed" do
    obj = mock("io")
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.close
    -> { io.fileno }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
