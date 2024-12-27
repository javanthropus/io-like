# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DelegatedIO#autoclose=" do
  it "returns the argument given" do
    obj = mock("io")
    # Satisfy the finalizer that will call #close on this object.
    def obj.close; end
    io = IO::LikeHelpers::DelegatedIO.new(obj)
    io.send(:autoclose=, true).should be_true
    io.send(:autoclose=, false).should be_false
    io.send(:autoclose=, :foo).should == :foo
  end

  it "causes the delegate to be closed when set to true" do
    obj = mock("io")
    # Satisfy the finalizer that will call #close on this object.
    def obj.close; end
    obj.should_receive(:close).and_return(nil)
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.autoclose = true
    io.close
  end

  it "causes the delegate to not be closed when set to false" do
    obj = mock("io")
    obj.should_not_receive(:close)
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.autoclose = false
    io.close
  end

  it "raises IOError if the stream is closed" do
    obj = mock("io")
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.close
    -> { io.send(:autoclose=, false) }.should raise_error(IOError, 'closed stream')
  end
end

describe "IO::LikeHelpers::DelegatedIO#autoclose?" do
  it "returns the truthiness of #autoclose=" do
    obj = mock("io")
    # Satisfy the finalizer that will call #close on this object.
    def obj.close; end
    io = IO::LikeHelpers::DelegatedIO.new(obj)

    io.autoclose = true
    io.autoclose?.should be_true

    io.autoclose = false
    io.autoclose?.should be_false

    io.autoclose = :foo
    io.autoclose?.should be_true
  end

  it "raises IOError if the stream is closed" do
    obj = mock("io")
    io = IO::LikeHelpers::DelegatedIO.new(obj, autoclose: false)
    io.close
    -> { io.autoclose? }.should raise_error(IOError, 'closed stream')
  end
end

# vim: ts=2 sw=2 et
