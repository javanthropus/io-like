# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::AbstractIO#ready?" do
  it "returns false" do
    io = IO::LikeHelpers::AbstractIO.new
    io.ready?.should be_false
  end

  it "raises IOError if the stream is closed" do
    io = IO::LikeHelpers::AbstractIO.new
    io.close
    -> { io.ready? }.should raise_error(IOError, 'closed stream')
  end
end
