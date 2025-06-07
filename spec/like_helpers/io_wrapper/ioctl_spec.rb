# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::IOWrapper#ioctl" do
  before :each do
    @name = tmp('io_wrapper_ioctl.txt')
    touch @name
    @io = File.open(@name)
  end

  after :each do
    @io.close
    rm_r @name
  end

  platform_is_not :windows do
    it "raises IOError on closed stream" do
      io = IO::LikeHelpers::IOWrapper.new(@io)
      @io.close
      -> { io.ioctl(5, 5) }.should raise_error(IOError)
    end
  end

  platform_is :linux do
    guard -> { RUBY_PLATFORM.include?("86") } do # x86 / x86_64
      it "resizes an empty String to match the output size" do
        File.open(__FILE__, 'r') do |f|
          buffer = String.new
          io = IO::LikeHelpers::IOWrapper.new(f)
          # FIONREAD in /usr/include/asm-generic/ioctls.h
          io.ioctl 0x541B, buffer
          buffer.unpack('I').first.should be_kind_of(Integer)
        end
      end
    end

    it "raises a system call error when ioctl fails" do
      File.open(__FILE__, 'r') do |f|
        io = IO::LikeHelpers::IOWrapper.new(f)
        -> {
          # TIOCGWINSZ in /usr/include/asm-generic/ioctls.h
          io.ioctl 0x5413, nil
        }.should raise_error(SystemCallError)
      end
    end
  end
end

# vim: ts=2 sw=2 et
