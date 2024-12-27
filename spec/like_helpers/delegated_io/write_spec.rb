# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DelegatedIO#write" do
  it "delegates to its delegate" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:write).with(buffer, length: 1).and_return(:result)
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.write(buffer, length: 1).should == :result
  end

  it "raises IOError when its delegate raises it" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:write).with(buffer, length: 1).and_raise(IOError.new('closed stream'))
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    -> { io.write(buffer, length: 1) }.should raise_error(IOError, 'closed stream')
  end

  it "defaults the number of bytes to write to the number of bytes in the buffer" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:write).with(buffer).and_return(:result)
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.write(buffer).should == :result
  end

  it "raises IOError if its delegate is not writable" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(false)
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    -> { io.write(buffer, length: 1) }.should raise_error(IOError, 'not opened for writing')
  end

  it "raises IOError if the stream is closed" do
    buffer = 'foo'.b
    obj = mock("io")
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.close
    -> { io.write(buffer, length: 1) }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
