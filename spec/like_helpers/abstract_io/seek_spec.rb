# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::AbstractIO#seek" do
  it "raises Errno::ESPIPE" do
    io = IO::LikeHelpers::AbstractIO.new
    -> { io.seek(1, :SET) }.should raise_error(Errno::ESPIPE)
  end

  it "raises IOError if the stream is closed" do
    io = IO::LikeHelpers::AbstractIO.new
    io.close
    -> { io.seek(1, :SET) }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
