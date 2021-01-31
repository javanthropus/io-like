# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DuplexedIO#autoclose=" do
  it "returns the argument given" do
    obj = mock("io")
    io = IO::LikeHelpers::DuplexedIO.new(obj)
    io.send(:autoclose=, true).should be_true
    io.send(:autoclose=, false).should be_false
    io.send(:autoclose=, :foo).should == :foo
  end

  it "raises IOError if the stream is closed" do
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close
    -> { io.send(:autoclose=, false) }.should raise_error(IOError, 'closed stream')
  end
end

describe "IO::LikeHelpers::DuplexedIO#autoclose?" do
  it "returns the truthiness of #autoclose=" do
    obj = mock("io")
    io = IO::LikeHelpers::DuplexedIO.new(obj)

    io.autoclose = true
    io.autoclose?.should be_true

    io.autoclose = false
    io.autoclose?.should be_false

    io.autoclose = :foo
    io.autoclose?.should be_true
  end

  it "raises IOError if the stream is closed" do
    obj_r = mock("reader_io")
    obj_w = mock("writer_io")
    io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
    io.close
    -> { io.autoclose? }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
