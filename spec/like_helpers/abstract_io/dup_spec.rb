# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::AbstractIO#dup" do
  it "raises IOError if the stream is closed" do
    io = IO::LikeHelpers::AbstractIO.new
    io.close
    -> { io.dup }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
