# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::BlockingIO#write" do
  it "returns a short write if the delegate does" do
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:write).and_return(5)
    io = IO::LikeHelpers::BlockingIO.new(obj, autoclose: false)
    io.write("\0" * 10).should == 5
  end

  it "blocks if the delegate would block" do
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:write).and_return(:wait_writable, 10)
    obj.should_receive(:wait).with(IO::WRITABLE, 1).and_return(nil)
    io = IO::LikeHelpers::BlockingIO.new(obj, autoclose: false)
    io.write("\0" * 10).should == 10
  end

  it "raises IOError if its delegate is not writable" do
    buffer = 'foo'.b
    obj = mock("io")
    obj.should_receive(:writable?).and_return(false)
    io = IO::LikeHelpers::BlockingIO.new(obj, autoclose: false)
    -> { io.write(buffer) }.should raise_error(IOError, 'not opened for writing')
  end

  it "raises IOError if the stream is closed" do
    buffer = 'foo'.b
    obj = mock("io")
    io = IO::LikeHelpers::BlockingIO.new(obj, autoclose: false)
    io.close
    -> { io.write(buffer) }.should raise_error(IOError, 'closed stream')
  end

  it "raises RuntimeError if delegate returns an unexpected result" do
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:write).and_return(:invalid)
    io = IO::LikeHelpers::BlockingIO.new(obj, autoclose: false)
    -> { io.write("\0") }.should raise_error(RuntimeError, 'Unexpected result: invalid')
  end

  it "ignores and retries if delegate raises Errno::EINTR" do
    obj = mock("io")
    # HACK:
    # Mspec mocks do not seem able to define a method that intermixes
    # returning results and raising exceptions.  Define such a method here and
    # a way to check that it was called enough times.
    def obj.write(buffer, length: buffer.bytesize)
      @times ||= 0
      @times += 1
      if @times == 1
        raise Errno::EINTR
      else
        return 1
      end
    end
    def obj.assert_complete
      raise "Called too few times" if @times < 2
    end
    obj.should_receive(:writable?).and_return(true)

    io = IO::LikeHelpers::BlockingIO.new(obj, autoclose: false)
    io.write("\0").should == 1

    obj.assert_complete
  end
end

# vim: ts=2 sw=2 et
