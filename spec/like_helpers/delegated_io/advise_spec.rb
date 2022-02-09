# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DelegatedIO#advise" do
  it "delegates to its delegate" do
    obj = mock("io")
    obj.should_receive(:advise).and_return(:result)
    io = IO::LikeHelpers::DelegatedIO.new(obj)
    io.advise(:foo).should == :result
  end

  it "raises IOError when its delegate raises it" do
    obj = mock("io")
    obj.should_receive(:advise).with(:foo).and_raise(IOError.new('closed stream'))
    io = IO::LikeHelpers::DelegatedIO.new(obj)
    -> { io.advise(:foo) }.should raise_error(IOError, 'closed stream')
  end

  it "raises IOError if the stream is closed" do
    obj = mock("io")
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.close
    -> { io.advise(:foo) }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
