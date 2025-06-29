# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DelegatedIO#seek" do
  it "delegates to its delegate" do
    obj = mock("io")
    obj.should_receive(:seek).with(1, :CUR).and_return(:result)
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.seek(1, :CUR).should == :result
  end

  it "raises Errno:ESPIPE when its delegate raises it" do
    obj = mock("io")
    obj.should_receive(:seek).with(1, :CUR).and_raise(Errno::ESPIPE)
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    -> { io.seek(1, :CUR) }.should raise_error(Errno::ESPIPE)
  end

  it "raises IOError if the stream is closed" do
    obj = mock("io")
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.close
    -> { io.seek(1, :CUR) }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
