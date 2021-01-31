# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::AbstractIO#ready?" do
  it "returns true" do
    io = IO::LikeHelpers::AbstractIO.new
    io.ready?.should be_true
  end

  it "raises IOError if the stream is closed" do
    io = IO::LikeHelpers::AbstractIO.new
    io.close
    -> { io.ready? }.should raise_error(IOError, 'closed stream')
  end
end
