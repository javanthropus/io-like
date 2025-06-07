# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DuplexedIO.new" do
  it "raises ArgumentError if the delegate_r is nil" do
    -> { IO::LikeHelpers::DuplexedIO.new(nil) }.should raise_error(ArgumentError)
  end

  it "raises ArgumentError if the delegate_w is nil" do
    -> { IO::LikeHelpers::DuplexedIO.new(:dummy, nil) }.should raise_error(ArgumentError)
  end

  it "enables autoclose by default" do
    obj_r = mock("reader_io")
    obj_r.should_receive(:close).and_return(nil).exactly(2)
    obj_w = mock("writer_io")
    obj_w.should_receive(:close).and_return(nil)

    io = IO::LikeHelpers::DuplexedIO.new(obj_r)
    io.autoclose?.should be_true
    io.close

    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w)
    io.autoclose?.should be_true
    io.close
  end

  it "allows autoclose to be set" do
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")

    io = IO::LikeHelpers::DuplexedIO.new(obj_r, autoclose: false)
    io.autoclose?.should be_false

    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.autoclose?.should be_false
  end
end

# vim: ts=2 sw=2 et
