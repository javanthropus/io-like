# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DelegatedIO.delegate" do
  it "adds an instance method" do
    obj = mock("io")
    obj.should_receive(:test_method).and_return(nil)

    # This creates a throwaway class in order to avoid polluting DelegatedIO
    # with test methods and the runtime environment with long lived classes
    # which may otherwise be reused between tests.
    clazz = IO::LikeHelpers::DelegatedIO.dup
    clazz.class_exec do
      delegate :test_method
    end

    io = clazz.new(obj)
    io.test_method.should be_nil
  end

  it "adds an instance method for assignment" do
    obj = mock("io")
    obj.should_receive(:test_method=).with('value').and_return(nil)

    # This creates a throwaway class in order to avoid polluting DelegatedIO
    # with test methods and the runtime environment with long lived classes
    # which may otherwise be reused between tests.
    clazz = IO::LikeHelpers::DelegatedIO.dup
    clazz.class_exec do
      delegate :test_method=
    end

    io = clazz.new(obj)
    io.test_method = 'value'
  end

  it "adds an instance method that delegates to the given delegate name" do
    obj = mock("io")
    obj.should_receive(:test_method).and_return(nil)

    # This creates a throwaway class in order to avoid polluting DelegatedIO
    # with test methods and the runtime environment with long lived classes
    # which may otherwise be reused between tests.
    clazz = IO::LikeHelpers::DelegatedIO.dup
    clazz.class_exec do
      attr_accessor :test_delegate
      delegate :test_method, to: :test_delegate
    end

    io = clazz.new('ignore')
    io.test_delegate = obj
    io.test_method.should be_nil
  end

  it "adds an instance method that asserts the delegate is readable" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(true)
    obj.should_receive(:test_method).and_return(nil)

    # This creates a throwaway class in order to avoid polluting DelegatedIO
    # with test methods and the runtime environment with long lived classes
    # which may otherwise be reused between tests.
    clazz = IO::LikeHelpers::DelegatedIO.dup
    clazz.class_exec do
      delegate :test_method, assert: :readable
    end

    io = clazz.new(obj)
    io.test_method.should be_nil
  end

  it "adds an instance method that asserts the delegate is writable" do
    obj = mock("io")
    obj.should_receive(:writable?).and_return(true)
    obj.should_receive(:test_method).and_return(nil)

    # This creates a throwaway class in order to avoid polluting DelegatedIO
    # with test methods and the runtime environment with long lived classes
    # which may otherwise be reused between tests.
    clazz = IO::LikeHelpers::DelegatedIO.dup
    clazz.class_exec do
      delegate :test_method, assert: :writable
    end

    io = clazz.new(obj)
    io.test_method.should be_nil
  end

  it "raises ArgumentError when given an invalid assertion" do
    -> do
      IO::LikeHelpers::DelegatedIO.send(:delegate, :method, to: nil, assert: :invalid)
    end.should raise_error(ArgumentError, 'Invalid assert: invalid')
  end
end

# vim: ts=2 sw=2 et
