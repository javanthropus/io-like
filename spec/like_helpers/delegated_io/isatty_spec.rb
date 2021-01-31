# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'
require_relative '../../../rubyspec/core/io/fixtures/classes'

describe "IO::LikeHelpers::DelegatedIO#isatty" do
  it "delegates to its delegate" do
    obj = mock("io")
    # NOTE:
    # #isatty is an alias for #tty?
    obj.should_receive(:tty?).and_return(:result)
    io = IO::LikeHelpers::DelegatedIO.new(obj)
    io.isatty.should == :result
  end

  it "raises IOError if the stream is closed" do
    obj = mock("io")
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.close
    -> { io.isatty }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
