# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::AbstractIO#pread" do
  it "delegates to #read" do
    # This creates a throwaway class in order to avoid polluting AbstractIO
    # with concrete method implementations and the runtime environment with long
    # lived classes which may otherwise be reused between tests.
    clazz = IO::LikeHelpers::AbstractIO.dup
    clazz.class_exec do
      def seek(offset, whence = :SET)
        0
      end
      def read(length, buffer: nil, buffer_offset: 0)
        length.should == 1
        buffer.should BeNilMatcher.new
        buffer_offset.should == 0
        "\0".b
      end
    end
    io = clazz.new

    io.pread(1, 2).should == "\0".b


    # This creates a throwaway class in order to avoid polluting AbstractIO
    # with concrete method implementations and the runtime environment with long
    # lived classes which may otherwise be reused between tests.
    clazz = IO::LikeHelpers::AbstractIO.dup
    clazz.class_exec do
      def seek(offset, whence = :SET)
        0
      end
      def read(length, buffer: nil, buffer_offset: 0)
        length.should == 1
        buffer.should == "\0".b
        buffer_offset.should == 0
        1
      end
    end
    io = clazz.new

    io.pread(1, 2, buffer: "\0".b).should == 1


    # This creates a throwaway class in order to avoid polluting AbstractIO
    # with concrete method implementations and the runtime environment with long
    # lived classes which may otherwise be reused between tests.
    clazz = IO::LikeHelpers::AbstractIO.dup
    clazz.class_exec do
      def seek(offset, whence = :SET)
        0
      end
      def read(length, buffer: nil, buffer_offset: 0)
        length.should == 1
        buffer.should == "\0\0".b
        buffer_offset.should == 1
        1
      end
    end
    io = clazz.new

    io.pread(1, 2, buffer: "\0\0".b, buffer_offset: 1).should == 1
  end

  it "reads at the offset and does not modify the stream position" do
    # This creates a throwaway class in order to avoid polluting AbstractIO
    # with concrete method implementations and the runtime environment with long
    # lived classes which may otherwise be reused between tests.
    clazz = IO::LikeHelpers::AbstractIO.dup
    clazz.class_exec do
      attr_accessor :pos
      def initialize
        @pos = 0
      end
      def seek(offset, whence = IO::SEEK_SET)
        case whence
        when IO::SEEK_SET
          @pos = offset
        when IO::SEEK_CUR
          @pos += offset
        end
        @pos
      end
      def read(length, buffer: nil, buffer_offset: 0)
        length.should == 1
        buffer.should BeNilMatcher.new
        @pos.should == 2
        @pos += length
        "\0".b
      end
    end
    io = clazz.new

    io.pread(1, 2).should == "\0".b
    io.pos.should == 0
  end
end

# vim: ts=2 sw=2 et
