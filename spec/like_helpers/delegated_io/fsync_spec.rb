# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'
require_relative '../../../rubyspec/core/io/fixtures/classes'

describe "IO::LikeHelpers::DelegatedIO#fsync" do
  it "delegates to its delegate" do
    obj = mock("io")
    obj.should_receive(:fsync).and_return(nil)
    io = IO::LikeHelpers::DelegatedIO.new(obj)
    io.fsync.should be_nil
  end
end

# vim: ts=2 sw=2 et
