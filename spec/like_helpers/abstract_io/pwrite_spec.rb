# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::AbstractIO#pwrite" do
  it "delegates to #write" do
    # This creates a throwaway class in order to avoid polluting AbstractIO
    # with concrete method implementations and the runtime environment with long
    # lived classes which may otherwise be reused between tests.
    clazz = IO::LikeHelpers::AbstractIO.dup
    clazz.class_exec do
      def seek(offset, whence = :SET)
        0
      end
      def write(buffer, length: buffer.size)
        buffer.should == "\0".b * 4
        length.should == buffer.size
        length
      end
    end
    io = clazz.new
    io.pwrite("\0".b * 4, 2).should == 4

    # This creates a throwaway class in order to avoid polluting AbstractIO
    # with concrete method implementations and the runtime environment with long
    # lived classes which may otherwise be reused between tests.
    clazz = IO::LikeHelpers::AbstractIO.dup
    clazz.class_exec do
      def seek(offset, whence = :SET)
        0
      end
      def write(buffer, length: buffer.size)
        buffer.should == "\0".b * 4
        length.should == 3
        length
      end
    end
    io = clazz.new
    io.pwrite("\0".b * 4, 2, length: 3).should == 3
  end

  it "writes at the offset and does not modify the stream position" do
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
      def write(buffer, length: buffer.size)
        buffer.should == "\0".b * 4
        length.should == buffer.size
        @pos.should == 2
        @pos += length
        length
      end
    end
    io = clazz.new

    io.pwrite("\0".b * 4, 2).should == 4
    io.pos.should == 0
  end
end

# vim: ts=2 sw=2 et
