# -*- encoding: utf-8 -*-
require_relative '../../spec_helper'

describe "IO::Like#pwrite" do
  it "raises NotImplementedError" do
    obj = mock("io")
    io = IO::Like.new(obj)
    -> { io.pwrite(0, 0) }.should raise_error(NotImplementedError)
  end
end

# vim: ts=2 sw=2 et
