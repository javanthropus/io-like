# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::BlockingIO#read" do
  it "returns a short read if the delegate does" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).and_return("\0" * 5, 5, 5)
    io = IO::LikeHelpers::BlockingIO.new(obj)
    io.read(10).should == "\0" * 5
    io.read(10, buffer: "\0" * 10).should == 5
    io.read(10, buffer: "\0" * 11, buffer_offset: 1).should == 5
  end

  it "blocks if the delegate would block" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).and_return(:wait_readable, "\0" * 10, :wait_readable, 10)
    obj.should_receive(:wait).with(IO::READABLE, 1).and_return(nil).exactly(2)
    io = IO::LikeHelpers::BlockingIO.new(obj)
    io.read(10).should == "\0" * 10
    io.read(10, buffer: "\0" * 10).should == 10
  end

  it "returns a short read if end of file is reached after reading some data" do
    IO.pipe do |r, w|
      w.write('bar' * 3)
      w.close
      io = IO::LikeHelpers::BlockingIO.new(IO::LikeHelpers::IOWrapper.new(r))
      io.read(100).should == 'bar' * 3
    end
  end

  it "raises EOFError if reading begins at end of file" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).and_raise(EOFError.new)
    io = IO::LikeHelpers::BlockingIO.new(obj)
    -> { io.read(1) }.should raise_error(EOFError)
  end

  it "raises IOError if its delegate is not readable" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(false)
    io = IO::LikeHelpers::BlockingIO.new(obj)
    -> { io.read(1) }.should raise_error(IOError, 'not opened for reading')
  end

  it "raises IOError if the stream is closed" do
    obj = mock("io")
    io = IO::LikeHelpers::BlockingIO.new(obj, autoclose: false)
    io.close
    -> { io.read(1) }.should raise_error(IOError, 'closed stream')
  end

  it "raises RuntimeError if delegate returns an unexpected result" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:read).and_return(:invalid)
    io = IO::LikeHelpers::BlockingIO.new(obj)
    -> { io.read(1) }.should raise_error(RuntimeError, 'Unexpected result: invalid')
  end

  it "ignores and retries if delegate raises Errno::EINTR" do
    obj = mock("io")
    # HACK:
    # Mspec mocks do not seem able to define a method that intermixes
    # returning results and raising exceptions.  Define such a method here and
    # a way to check that it was called enough times.
    def obj.read(length, buffer: nil, buffer_offset: 0)
      @times ||= 0
      @times += 1
      if @times == 1
        raise Errno::EINTR
      else
        return 'c'
      end
    end
    def obj.assert_complete
      raise "Called too few times" if @times < 2
    end
    obj.should_receive(:readable?).and_return(true)

    io = IO::LikeHelpers::BlockingIO.new(obj)
    io.read(1).should == 'c'

    obj.assert_complete
  end
end

# vim: ts=2 sw=2 et
