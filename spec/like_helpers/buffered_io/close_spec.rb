# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::BufferedIO#close" do
  it "delegates to its delegate when #autoclose? is true" do
    obj = mock("io")
    obj.should_receive(:close).and_return(nil)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.close.should be_nil
  end

  it "does not delegate to its delegate when #autoclose? is false" do
    obj = mock("io")
    io = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
    io.close.should be_nil
  end

  it "returns a Symbol if its delegate does so" do
    obj = mock("io")
    obj.should_receive(:close).and_return(:wait_readable)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.close.should == :wait_readable

    # Disable the finalizer that would attempt to close the mock delegate and
    # break the test.
    io.autoclose = false
  end

  it "flushes the write buffer" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:write).with(buffer).and_return(3)
    obj.should_receive(:close).and_return(nil)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.write(buffer)
    io.close.should be_nil
  end

  it "short circuits after the first call" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:write).with(buffer).and_return(3)
    obj.should_receive(:close).and_return(nil)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.write(buffer)
    io.close.should be_nil
    io.close.should be_nil
  end

  it "returns a Symbol if delegate.write does so when there is buffered data" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:write).with(buffer).and_return(:wait_readable)
    io = IO::LikeHelpers::BufferedIO.new(obj)
    io.write(buffer)
    io.close.should == :wait_readable

    # Disable the finalizer that would attempt to close the mock delegate and
    # break the test.
    io.autoclose = false
  end
end

# vim: ts=2 sw=2 et
