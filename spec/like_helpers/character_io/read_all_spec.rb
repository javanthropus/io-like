# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

require 'io/like_helpers/buffered_io'
require 'io/like_helpers/character_io'

describe "IO::LikeHelpers::CharacterIO#read_all" do
  it "raises IOError if the stream is not readable" do
    obj = mock("io")
    obj.should_receive(:readable?).and_return(false)
    io = IO::LikeHelpers::CharacterIO.new(
      IO::LikeHelpers::BufferedIO.new(obj),
      external_encoding: Encoding::UTF_8
    )
    lambda { io.read_all }.should raise_error(IOError)
  end

  describe "when transcoding" do
    it "returns all remaining characters from the stream" do
      content = "a\nb\nc"
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      # HACK:
      # Mspec mocks do not seem able to define a method that intermixes
      # returning results and raising exceptions.  Define such a method here and
      # a way to check that it was called enough times.
      obj.instance_variable_set(:@content, content)
      def obj.read(length, buffer: nil, buffer_offset: 0)
        @times ||= 0
        @times += 1
        if @times == 1
          buffer[buffer_offset, @content.bytesize] = @content.b
          return @content.bytesize
        else
          raise EOFError
        end
      end
      def obj.assert_complete
        raise "Called too few times" if @times < 2
      end

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj),
        external_encoding: Encoding::UTF_8,
        internal_encoding: Encoding::UTF_16LE
      )
      io.read_all.should == content.encode(Encoding::UTF_16LE)

      obj.assert_complete
    end

    it "returns the character pushed onto the internal buffer" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      obj.should_receive(:read).and_raise(EOFError)
      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj),
        external_encoding: Encoding::UTF_8,
        internal_encoding: Encoding::UTF_16LE
      )
      io.unread("a".encode(Encoding::UTF_16LE).b)
      io.read_all.should == "a".encode(Encoding::UTF_16LE)
    end

    it "returns partial characters from the internal buffer at end of file" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      obj.should_receive(:read).and_raise(EOFError)
      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj),
        external_encoding: Encoding::UTF_8,
        internal_encoding: Encoding::UTF_16LE
      )
      io.unread("a".b)
      io.read_all.should == "a".force_encoding(Encoding::UTF_16LE)
    end

    it "obeys the universal newline decorator when set" do
      content = "a\rb\nc\r\nd\r"
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      # HACK:
      # Mspec mocks do not seem able to define a method that intermixes
      # returning results and raising exceptions.  Define such a method here and
      # a way to check that it was called enough times.
      obj.instance_variable_set(:@content, content)
      def obj.read(length, buffer: nil, buffer_offset: 0)
        @times ||= 0
        @times += 1
        if @times == 1
          buffer[buffer_offset, @content.bytesize] = @content.b
          return @content.bytesize
        else
          raise EOFError
        end
      end
      def obj.assert_complete
        raise "Called too few times" if @times < 2
      end

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj),
        external_encoding: Encoding::UTF_8,
        internal_encoding: Encoding::UTF_16LE,
        encoding_opts: {newline: :universal}
      )
      io.read_all.should == content.encode(Encoding::UTF_16LE, newline: :universal)

      obj.assert_complete
    end

    it "omits newline handling when the universal newline decorator is not set" do
      content = "a\rb\nc\r\nd\r"
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      # HACK:
      # Mspec mocks do not seem able to define a method that intermixes
      # returning results and raising exceptions.  Define such a method here and
      # a way to check that it was called enough times.
      obj.instance_variable_set(:@content, content)
      def obj.read(length, buffer: nil, buffer_offset: 0)
        @times ||= 0
        @times += 1
        if @times == 1
          buffer[buffer_offset, @content.bytesize] = @content.b
          return @content.bytesize
        else
          raise EOFError
        end
      end
      def obj.assert_complete
        raise "Called too few times" if @times < 2
      end

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj),
        external_encoding: Encoding::UTF_8,
        internal_encoding: Encoding::UTF_16LE
      )
      io.read_all.should == content.encode(Encoding::UTF_16LE)

      obj.assert_complete
    end

    it "raises EOFError if called at the end of the stream" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      obj.should_receive(:read).and_raise(EOFError)
      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj),
        external_encoding: Encoding::UTF_8,
        internal_encoding: Encoding::UTF_16LE
      )
      -> { io.read_all }.should raise_error(EOFError)
    end

    it "raises Encoding::InvalidByteSequenceError for an invalid byte sequence" do
      content = "\xE3\x81\xE3"
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      # HACK:
      # Mspec mocks do not seem able to define a method that intermixes
      # returning results and raising exceptions.  Define such a method here and
      # a way to check that it was called enough times.
      obj.instance_variable_set(:@content, content)
      def obj.read(length, buffer: nil, buffer_offset: 0)
        @times ||= 0
        @times += 1
        if @times == 1
          buffer[buffer_offset, @content.bytesize] = @content.b
          return @content.bytesize
        else
          raise EOFError
        end
      end
      def obj.assert_complete
        raise "Called too few times" if @times < 2
      end
      bio = IO::LikeHelpers::BufferedIO.new(obj)
      io = IO::LikeHelpers::CharacterIO.new(
        bio,
        external_encoding: Encoding::UTF_8,
        internal_encoding: Encoding::UTF_16LE
      )
      -> { io.read_all }.should raise_error(Encoding::InvalidByteSequenceError)
      # Verify that the byte after the invalid byte sequence is still available
      # to read.
      bio.read(1).should == "\xE3".b
    end

    it "raises Encoding::InvalidByteSequenceError for an incomplete byte sequence at the end of file" do
      content = "\xE3\x81"
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      # HACK:
      # Mspec mocks do not seem able to define a method that intermixes
      # returning results and raising exceptions.  Define such a method here and
      # a way to check that it was called enough times.
      obj.instance_variable_set(:@content, content)
      def obj.read(length, buffer: nil, buffer_offset: 0)
        @times ||= 0
        @times += 1
        if @times == 1
          buffer[buffer_offset, @content.bytesize] = @content.b
          return @content.bytesize
        else
          raise EOFError
        end
      end
      def obj.assert_complete
        raise "Called too few times" if @times < 2
      end

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj),
        external_encoding: Encoding::UTF_8,
        internal_encoding: Encoding::UTF_16LE
      )
      -> { io.read_all }.should raise_error(Encoding::InvalidByteSequenceError)

      obj.assert_complete
    end

    it "raises Encoding::UndefinedConversionError when a character cannot be transcoded" do
      content = "🍣"
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      # HACK:
      # Mspec mocks do not seem able to define a method that intermixes
      # returning results and raising exceptions.  Define such a method here and
      # a way to check that it was called enough times.
      obj.instance_variable_set(:@content, content)
      def obj.read(length, buffer: nil, buffer_offset: 0)
        @times ||= 0
        @times += 1
        if @times == 1
          buffer[buffer_offset, @content.bytesize] = @content.b
          return @content.bytesize
        else
          raise EOFError
        end
      end
      def obj.assert_complete
        raise "Called too few times" if @times < 2
      end

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj),
        external_encoding: Encoding::UTF_8,
        internal_encoding: Encoding::Windows_31J
      )
      -> { io.read_all }.should raise_error(Encoding::UndefinedConversionError)
    end

    describe "with an incomplete character in the internal buffer" do
      it "returns the next character composed of bytes from the internal buffer and the stream" do
        char_ext = "🍣"
        char_int = char_ext.encode(Encoding::UTF_16LE)
        obj = mock("io")
        obj.should_receive(:readable?).and_return(true)
        # HACK:
        # Mspec mocks do not seem able to define a method that intermixes
        # returning results and raising exceptions.  Define such a method here and
        # a way to check that it was called enough times.
        obj.instance_variable_set(:@content, char_ext)
        def obj.read(length, buffer: nil, buffer_offset: 0)
          @times ||= 0
          @times += 1
          if @times == 1
            buffer[buffer_offset, @content.bytesize] = @content.b
            return @content.bytesize
          else
            raise EOFError
          end
        end
        def obj.assert_complete
          raise "Called too few times" if @times < 2
        end

        io = IO::LikeHelpers::CharacterIO.new(
          IO::LikeHelpers::BufferedIO.new(obj),
          external_encoding: Encoding::UTF_8,
          internal_encoding: Encoding::UTF_16LE
        )
        io.unread(char_int.b[0, 3])
        io.read_all.should == (char_int.b[0, 3] + char_int.b).force_encoding(Encoding::UTF_16LE)

        obj.assert_complete
      end
    end
  end

  describe "when not transcoding" do
    it "returns all remaining characters from the stream" do
      content = "a\nb\nc"
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      # HACK:
      # Mspec mocks do not seem able to define a method that intermixes
      # returning results and raising exceptions.  Define such a method here and
      # a way to check that it was called enough times.
      obj.instance_variable_set(:@content, content)
      def obj.read(length, buffer: nil, buffer_offset: 0)
        @times ||= 0
        @times += 1
        if @times == 1
          buffer[buffer_offset, @content.bytesize] = @content.b
          return @content.bytesize
        else
          raise EOFError
        end
      end
      def obj.assert_complete
        raise "Called too few times" if @times < 2
      end

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj),
        external_encoding: Encoding::UTF_8
      )
      io.read_all.should == content

      obj.assert_complete
    end

    it "returns content encoded with the default external encoding if not set for the stream and the stream is writable" do
      content = "a\nb\nc"
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      # HACK:
      # Mspec mocks do not seem able to define a method that intermixes
      # returning results and raising exceptions.  Define such a method here and
      # a way to check that it was called enough times.
      obj.instance_variable_set(:@content, content)
      def obj.read(length, buffer: nil, buffer_offset: 0)
        @times ||= 0
        @times += 1
        if @times == 1
          buffer[buffer_offset, @content.bytesize] = @content.b
          return @content.bytesize
        else
          raise EOFError
        end
      end
      def obj.assert_complete
        raise "Called too few times" if @times < 2
      end
      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj)
      )

      begin
        default_external = Encoding.default_external
        Encoding.default_external = Encoding::ISO_8859_1

        io.read_all.encoding.should == Encoding::ISO_8859_1
      ensure
        Encoding.default_external = default_external
      end

      obj.assert_complete
    end

    it "returns content encoded with the default external encoding if not set for the stream and the stream is not writable" do
      content = "a\nb\nc"
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      # HACK:
      # Mspec mocks do not seem able to define a method that intermixes
      # returning results and raising exceptions.  Define such a method here and
      # a way to check that it was called enough times.
      obj.instance_variable_set(:@content, content)
      def obj.read(length, buffer: nil, buffer_offset: 0)
        @times ||= 0
        @times += 1
        if @times == 1
          buffer[buffer_offset, @content.bytesize] = @content.b
          return @content.bytesize
        else
          raise EOFError
        end
      end
      def obj.assert_complete
        raise "Called too few times" if @times < 2
      end
      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj)
      )

      begin
        default_external = Encoding.default_external
        Encoding.default_external = Encoding::ISO_8859_1

        io.read_all.encoding.should == Encoding::ISO_8859_1
      ensure
        Encoding.default_external = default_external
      end

      obj.assert_complete
    end

    it "returns the character pushed onto the internal buffer" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      obj.should_receive(:read).and_raise(EOFError)
      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj),
        external_encoding: Encoding::UTF_8,
        encoding_opts: {newline: :universal}
      )
      io.unread("a".b)
      io.read_all.should == "a"
    end

    it "returns partial characters from the internal buffer at end of file" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      obj.should_receive(:read).and_raise(EOFError)
      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj),
        external_encoding: Encoding::UTF_8,
        encoding_opts: {newline: :universal}
      )
      io.unread("\xE3".b)
      io.read_all.should == "\xE3"
    end

    it "obeys the universal newline decorator when set" do
      content = "a\rb\nc\r\nd\r"
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      # HACK:
      # Mspec mocks do not seem able to define a method that intermixes
      # returning results and raising exceptions.  Define such a method here and
      # a way to check that it was called enough times.
      obj.instance_variable_set(:@content, content)
      def obj.read(length, buffer: nil, buffer_offset: 0)
        @times ||= 0
        @times += 1
        if @times == 1
          buffer[buffer_offset, @content.bytesize] = @content.b
          return @content.bytesize
        else
          raise EOFError
        end
      end
      def obj.assert_complete
        raise "Called too few times" if @times < 2
      end

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj),
        external_encoding: Encoding::UTF_8,
        encoding_opts: {newline: :universal}
      )
      io.read_all.should == content.encode(content.encoding, newline: :universal)

      obj.assert_complete
    end

    it "omits newline handling when the universal newline decorator is not set" do
      content = "a\rb\nc\r\nd\r"
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      # HACK:
      # Mspec mocks do not seem able to define a method that intermixes
      # returning results and raising exceptions.  Define such a method here and
      # a way to check that it was called enough times.
      obj.instance_variable_set(:@content, content)
      def obj.read(length, buffer: nil, buffer_offset: 0)
        @times ||= 0
        @times += 1
        if @times == 1
          buffer[buffer_offset, @content.bytesize] = @content.b
          return @content.bytesize
        else
          raise EOFError
        end
      end
      def obj.assert_complete
        raise "Called too few times" if @times < 2
      end

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj),
        external_encoding: Encoding::UTF_8
      )
      io.read_all.should == content.encode(content.encoding)

      obj.assert_complete
    end

    it "raises EOFError if called at the end of the stream" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      obj.should_receive(:read).and_raise(EOFError)
      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj),
        external_encoding: Encoding::UTF_8
      )
      -> { io.read_all }.should raise_error(EOFError)
    end
  end
end

# vim: ts=2 sw=2 et
