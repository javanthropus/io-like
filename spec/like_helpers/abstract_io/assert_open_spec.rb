# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

# This is a special case test for a private method to cover a code path that
# isn't testable via the public instance methods.
describe "IO::LikeHelpers::AbstractIO#assert_open" do
  it "raises IOError if the stream is not initialized" do
    io = IO::LikeHelpers::AbstractIO.allocate
    -> { io.send(:assert_open) }.should raise_error(IOError)
  end
end
