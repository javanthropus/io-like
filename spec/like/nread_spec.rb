# -*- encoding: utf-8 -*-
require_relative '../../spec_helper'

describe "IO::Like#nread" do
  it "delegates to its delegate" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    io = IO::Like.new(obj)
    io.nread.should == 0
  end

  it "raises IOError if its delegate is not readable" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(false)
    io = IO::Like.new(obj)
    -> { io.nread }.should raise_error(IOError, 'not opened for reading')
  end

  it "raises IOError if the stream is closed" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(false)
    obj.should_receive(:writable?).and_return(false)
    io = IO::Like.new(obj, autoclose: false)
    io.close
    -> { io.nread }.should raise_error(IOError, 'closed stream')
  end

  it "raises IOError if the character buffer is not empty" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    io = IO::Like.new(obj, encoding: 'utf-8:utf-16le')
    io.ungetc("a".encode("utf-16le"))
    -> {
      io.nread
    }.should raise_error(IOError, 'byte oriented read for character buffered IO')
  end
end

# vim: ts=2 sw=2 et
