# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::AbstractIO.open" do
  it "passes all arguments to .new" do
    IO::LikeHelpers::AbstractIO.should_receive(:new)
      .with('arg1', 'arg2', kwarg1: 'val1', kwarg2: 'val2')
      .and_return(nil)
    IO::LikeHelpers::AbstractIO.open(
      'arg1', 'arg2', kwarg1: 'val1', kwarg2: 'val2'
    )
  end

  it "is equivalent to .new if no block is given" do
    io = IO::LikeHelpers::AbstractIO.open
    io.class.should == IO::LikeHelpers::AbstractIO
  end

  it "yields the new instance to a given block and returns the block result" do
    IO::LikeHelpers::AbstractIO.open do |io|
      io.class.should == IO::LikeHelpers::AbstractIO
      "result"
    end.should == "result"
  end

  it "closes the new instance when given a block" do
    IO::LikeHelpers::AbstractIO.open do |io|
      io.should_receive(:close).and_return(nil)
    end
  end

  it "retries closing the instance when given a block during a nonblocking close" do
    -> {
    IO::LikeHelpers::AbstractIO.open do |io|
      io.should_receive(:close).and_return(:wait_readable, nil)
      io.should_receive(:wait)
    end
    }.should complain(/^warning: waiting for nonblocking close to complete at the end of the open method$/)
  end
end

# vim: ts=2 sw=2 et
