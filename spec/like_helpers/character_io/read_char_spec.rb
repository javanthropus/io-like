# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

require 'io/like_helpers/buffered_io'
require 'io/like_helpers/character_io'

describe "IO::LikeHelpers::CharacterIO#read_char" do
  describe "when transcoding without the universal newline decorator set" do
    it "raises IOError if the stream is not readable" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(false)

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: Encoding::UTF_8,
        internal_encoding: Encoding::UTF_16LE
      )
      lambda { io.read_char }.should raise_error(IOError)
    end

    it "raises EOFError if called at the end of the stream" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      obj.should_receive(:read).and_raise(EOFError)

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: Encoding::UTF_8,
        internal_encoding: Encoding::UTF_16LE
      )
      -> { io.read_char }.should raise_error(EOFError)
    end

    it "returns the next character from the stream" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      # HACK:
      # Mspec mocks are not able to mutate arguments, but that is necessary for
      # #read when the buffer argument is not nil as will be the case here.
      # Emulate peforming a short read.  The checks on the results of the read
      # operations on the BufferedIO instance will serve as validation that the
      # method was called.
      def obj.read(length, buffer: nil, buffer_offset: 0)
        content = "a".b
        buffer[buffer_offset, content.bytesize] = content
        content.bytesize
      end

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: Encoding::UTF_8,
        internal_encoding: Encoding::UTF_16LE
      )
      io.read_char.should == "a".encode(Encoding::UTF_16LE)
    end

    it "returns the character pushed onto the internal buffer" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: Encoding::UTF_8,
        internal_encoding: Encoding::UTF_16LE
      )
      io.unread("a".encode(Encoding::UTF_16LE).b)
      io.read_char.should == "a".encode(Encoding::UTF_16LE)
    end

    it "omits newline handling" do
      cr = "\r".b
      nl = "\n".b
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      # HACK:
      # Mspec mocks are not able to mutate arguments, but that is necessary for
      # #read when the buffer argument is not nil as will be the case here.
      # Emulate peforming a short read.  The checks on the results of the read
      # operations on the BufferedIO instance will serve as validation that the
      # method was called.
      def obj.read(length, buffer: nil, buffer_offset: 0)
        content = "\r\r\n\n".b
        buffer[buffer_offset, content.bytesize] = content
        content.bytesize
      end

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: Encoding::UTF_8,
        internal_encoding: Encoding::UTF_16LE
      )
      io.read_char.should == cr.encode(Encoding::UTF_16LE)
      io.read_char.should == cr.encode(Encoding::UTF_16LE)
      io.read_char.should == nl.encode(Encoding::UTF_16LE)
      io.read_char.should == nl.encode(Encoding::UTF_16LE)
    end

    it "raises Encoding::InvalidByteSequenceError for an invalid byte sequence" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      # HACK:
      # Mspec mocks are not able to mutate arguments, but that is necessary for
      # #read when the buffer argument is not nil as will be the case here.
      # Emulate peforming a short read.  The checks on the results of the read
      # operations on the BufferedIO instance will serve as validation that the
      # method was called.
      def obj.read(length, buffer: nil, buffer_offset: 0)
        # Return a stream of bytes that do not form a valid UTF-8 character.
        content = "\xE3\x81\xE3".b
        buffer[buffer_offset, content.bytesize] = content
        content.bytesize
      end

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: Encoding::UTF_8,
        internal_encoding: Encoding::UTF_16LE
      )
      -> { io.read_char }.should raise_error(Encoding::InvalidByteSequenceError)
    end

    it "returns the next character after raising Encoding::InvalidByteSequenceError" do
      char = "🍣"
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      # HACK:
      # Mspec mocks are not able to mutate arguments, but that is necessary for
      # #read when the buffer argument is not nil as will be the case here.
      # Emulate peforming a short read.  The checks on the results of the read
      # operations on the BufferedIO instance will serve as validation that the
      # method was called.
      def obj.read(length, buffer: nil, buffer_offset: 0)
        # Return a stream of bytes that do not start with a valid UTF-16LE character.
        content = "\x00\xd8".b + "🍣".encode(Encoding::UTF_16LE).b
        buffer[buffer_offset, content.bytesize] = content
        content.bytesize
      end

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: Encoding::UTF_16LE,
        internal_encoding: Encoding::UTF_8
      )
      -> { io.read_char }.should raise_error(Encoding::InvalidByteSequenceError)
      io.read_char.should == char
    end

    it "puts buffered bytes back into the delegate after raising Encoding::InvalidByteSequenceError" do
      char = "🍣"
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      # HACK:
      # Mspec mocks are not able to mutate arguments, but that is necessary for
      # #read when the buffer argument is not nil as will be the case here.
      # Emulate peforming a short read.  The checks on the results of the read
      # operations on the BufferedIO instance will serve as validation that the
      # method was called.
      def obj.read(length, buffer: nil, buffer_offset: 0)
        # Return a stream of bytes that do not start with a valid UTF-16LE character.
        content = "\x00\xd8".b + "🍣".encode(Encoding::UTF_16LE).b
        buffer[buffer_offset, content.bytesize] = content
        content.bytesize
      end

      bio = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
      io = IO::LikeHelpers::CharacterIO.new(
        bio,
        external_encoding: Encoding::UTF_16LE,
        internal_encoding: Encoding::UTF_8
      )
      -> { io.read_char }.should raise_error(Encoding::InvalidByteSequenceError)
      bio.read(char.bytesize) == char.b
    end

    it "raises Encoding::InvalidByteSequenceError for an incomplete byte sequence at the end of file" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      # HACK:
      # Mspec mocks are not able to mutate arguments, but that is necessary for
      # #read when the buffer argument is not nil as will be the case here.
      # Emulate peforming a short read.  The checks on the results of the read
      # operations on the BufferedIO instance will serve as validation that the
      # method was called.
      def obj.read(length, buffer: nil, buffer_offset: 0)
        @times ||= 0
        @times += 1
        if @times == 1
          content = "\xE3\x81".b
          buffer[buffer_offset, content.bytesize] = content
          content.bytesize
        else
          raise EOFError
        end
      end
      def obj.assert_complete
        raise "Called too few times" if @times < 2
      end

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: Encoding::UTF_8,
        internal_encoding: Encoding::UTF_16LE
      )
      -> { io.read_char }.should raise_error(Encoding::InvalidByteSequenceError)
      obj.assert_complete
    end

    it "raises Encoding::UndefinedConversionError when a character cannot be transcoded" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      # HACK:
      # Mspec mocks are not able to mutate arguments, but that is necessary for
      # #read when the buffer argument is not nil as will be the case here.
      # Emulate peforming a short read.  The checks on the results of the read
      # operations on the BufferedIO instance will serve as validation that the
      # method was called.
      def obj.read(length, buffer: nil, buffer_offset: 0)
        content = "🍣".b
        buffer[buffer_offset, content.bytesize] = content
        content.bytesize
      end

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: Encoding::UTF_8,
        internal_encoding: Encoding::Windows_31J
      )
      -> { io.read_char }.should raise_error(Encoding::UndefinedConversionError)
    end

    describe "with an incomplete character in the internal buffer" do
      it "returns invalid characters composed of bytes from the internal buffer when the stream is ended" do
        char_int = "🍣".encode(Encoding::UTF_16LE)
        obj = mock("io")
        obj.should_receive(:readable?).and_return(true)
        obj.should_receive(:read).at_least(1).and_raise(EOFError)

        io = IO::LikeHelpers::CharacterIO.new(
          IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
          external_encoding: Encoding::UTF_8,
          internal_encoding: Encoding::UTF_16LE
        )
        io.unread(char_int.b[0..-2])
        io.read_char.should == String.new("\x3C\xD8").force_encoding(Encoding::UTF_16LE)
        io.read_char.should == String.new("\x63").force_encoding(Encoding::UTF_16LE)
      end

      it "returns invalid characters composed of bytes from the internal buffer and converted bytes from the stream" do
        char_int = "🍣".encode(Encoding::UTF_16LE)
        obj = mock("io")
        obj.should_receive(:readable?).and_return(true)
        # HACK:
        # Mspec mocks are not able to mutate arguments, but that is necessary
        # for #read when the buffer argument is not nil as will be the case
        # here.  Emulate peforming a short read.  The checks on the results of
        # the read operations on the BufferedIO instance will serve as
        # validation that the method was called.
        def obj.read(length, buffer: nil, buffer_offset: 0)
          @times ||= 0
          @times += 1
          if @times == 1
            content = "🍣".b
            buffer[buffer_offset, content.bytesize] = content
            content.bytesize
          else
            raise EOFError
          end
        end
        def obj.assert_complete
          raise "Called too few times" if @times < 2
        end

        io = IO::LikeHelpers::CharacterIO.new(
          IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
          external_encoding: Encoding::UTF_8,
          internal_encoding: Encoding::UTF_16LE
        )
        io.unread(char_int.b[0..-2])
        io.read_char.should == String.new("\x3C\xD8").force_encoding(Encoding::UTF_16LE)
        io.read_char.should == String.new("\x63\x3C").force_encoding(Encoding::UTF_16LE)
        io.read_char.should == String.new("\xD8\x63").force_encoding(Encoding::UTF_16LE)
        io.read_char.should == String.new("\xDF").force_encoding(Encoding::UTF_16LE)
        obj.assert_complete
      end
    end
  end

  describe "when transcoding while the universal newline decorator is set" do
    it "raises IOError if the stream is not readable" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(false)

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: Encoding::UTF_8,
        internal_encoding: Encoding::UTF_16LE,
        encoding_opts: {newline: :universal}
      )
      lambda { io.read_char }.should raise_error(IOError)
    end

    it "raises EOFError if called at the end of the stream" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      obj.should_receive(:read).and_raise(EOFError)

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: Encoding::UTF_8,
        internal_encoding: Encoding::UTF_16LE,
        encoding_opts: {newline: :universal}
      )
      -> { io.read_char }.should raise_error(EOFError)
    end

    it "returns the next character from the stream" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      # HACK:
      # Mspec mocks are not able to mutate arguments, but that is necessary for
      # #read when the buffer argument is not nil as will be the case here.
      # Emulate peforming a short read.  The checks on the results of the read
      # operations on the BufferedIO instance will serve as validation that the
      # method was called.
      def obj.read(length, buffer: nil, buffer_offset: 0)
        content = "a".b
        buffer[buffer_offset, content.bytesize] = content
        content.bytesize
      end

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: Encoding::UTF_8,
        internal_encoding: Encoding::UTF_16LE,
        encoding_opts: {newline: :universal}
      )
      io.read_char.should == "a".encode(Encoding::UTF_16LE)
    end

    it "returns the character pushed onto the internal buffer" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: Encoding::UTF_8,
        internal_encoding: Encoding::UTF_16LE,
        encoding_opts: {newline: :universal}
      )
      io.unread("a".encode(Encoding::UTF_16LE).b)
      io.read_char.should == "a".encode(Encoding::UTF_16LE)
    end

    it "obeys the universal newline decorator" do
      cr = "\r".b
      nl = "\n".b
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      # HACK:
      # Mspec mocks are not able to mutate arguments, but that is necessary for
      # #read when the buffer argument is not nil as will be the case here.
      # Emulate peforming a short read.  The checks on the results of the read
      # operations on the BufferedIO instance will serve as validation that the
      # method was called.
      def obj.read(length, buffer: nil, buffer_offset: 0)
        content = "\r\r\n\n".b
        buffer[buffer_offset, content.bytesize] = content
        content.bytesize
      end

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: Encoding::UTF_8,
        internal_encoding: Encoding::UTF_16LE,
        encoding_opts: {newline: :universal}
      )
      io.read_char.should == nl.encode(Encoding::UTF_16LE)
      io.read_char.should == nl.encode(Encoding::UTF_16LE)
      io.read_char.should == nl.encode(Encoding::UTF_16LE)
    end

    it "converts carriage return at end of file to newline" do
      cr = "\r".b
      nl = "\n".b

      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      # HACK:
      # Mspec mocks do not seem able to define a method that intermixes
      # returning results and raising exceptions.  Define such a method here and
      # a way to check that it was called enough times.
      def obj.read(length, buffer: nil, buffer_offset: 0)
        @times ||= 0
        @times += 1
        if @times == 1
          content = "\r".b
          buffer[buffer_offset, content.bytesize] = content
          content.bytesize
        else
          raise EOFError
        end
      end
      def obj.assert_complete
        raise "Called too few times" if @times < 2
      end

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: Encoding::UTF_8,
        internal_encoding: Encoding::UTF_16LE,
        encoding_opts: {newline: :universal}
      )
      io.read_char.should == nl.encode(Encoding::UTF_16LE)
      obj.assert_complete
    end

    it "raises Encoding::InvalidByteSequenceError for an invalid byte sequence" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      # HACK:
      # Mspec mocks are not able to mutate arguments, but that is necessary for
      # #read when the buffer argument is not nil as will be the case here.
      # Emulate peforming a short read.  The checks on the results of the read
      # operations on the BufferedIO instance will serve as validation that the
      # method was called.
      def obj.read(length, buffer: nil, buffer_offset: 0)
        # Return a stream of bytes that do not form a valid UTF-8 character.
        content = "\xE3\x81\xE3".b
        buffer[buffer_offset, content.bytesize] = content
        content.bytesize
      end

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: Encoding::UTF_8,
        internal_encoding: Encoding::UTF_16LE,
        encoding_opts: {newline: :universal}
      )
      -> { io.read_char }.should raise_error(Encoding::InvalidByteSequenceError)
    end

    it "returns the next character after raising Encoding::InvalidByteSequenceError" do
      char = "🍣"
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      # HACK:
      # Mspec mocks are not able to mutate arguments, but that is necessary for
      # #read when the buffer argument is not nil as will be the case here.
      # Emulate peforming a short read.  The checks on the results of the read
      # operations on the BufferedIO instance will serve as validation that the
      # method was called.
      def obj.read(length, buffer: nil, buffer_offset: 0)
        # Return a stream of bytes that do not start with a valid UTF-16LE character.
        content = "\x00\xd8".b + "🍣".encode(Encoding::UTF_16LE).b
        buffer[buffer_offset, content.bytesize] = content
        content.bytesize
      end

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: Encoding::UTF_16LE,
        internal_encoding: Encoding::UTF_8,
        encoding_opts: {newline: :universal}
      )
      -> { io.read_char }.should raise_error(Encoding::InvalidByteSequenceError)
      io.read_char.should == char
    end

    it "puts buffered bytes back into the delegate after raising Encoding::InvalidByteSequenceError" do
      char = "🍣"
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      # HACK:
      # Mspec mocks are not able to mutate arguments, but that is necessary for
      # #read when the buffer argument is not nil as will be the case here.
      # Emulate peforming a short read.  The checks on the results of the read
      # operations on the BufferedIO instance will serve as validation that the
      # method was called.
      def obj.read(length, buffer: nil, buffer_offset: 0)
        # Return a stream of bytes that do not start with a valid UTF-16LE character.
        content = "\x00\xd8".b + "🍣".encode(Encoding::UTF_16LE).b
        buffer[buffer_offset, content.bytesize] = content
        content.bytesize
      end

      bio = IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
      io = IO::LikeHelpers::CharacterIO.new(
        bio,
        external_encoding: Encoding::UTF_16LE,
        internal_encoding: Encoding::UTF_8,
        encoding_opts: {newline: :universal}
      )
      -> { io.read_char }.should raise_error(Encoding::InvalidByteSequenceError)
      bio.read(char.bytesize) == char.b
    end

    it "raises Encoding::InvalidByteSequenceError for an incomplete byte sequence at the end of file" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      # HACK:
      # Mspec mocks are not able to mutate arguments, but that is necessary for
      # #read when the buffer argument is not nil as will be the case here.
      # Emulate peforming a short read.  The checks on the results of the read
      # operations on the BufferedIO instance will serve as validation that the
      # method was called.
      def obj.read(length, buffer: nil, buffer_offset: 0)
        @times ||= 0
        @times += 1
        if @times == 1
          content = "\xE3\x81".b
          buffer[buffer_offset, content.bytesize] = content
          content.bytesize
        else
          raise EOFError
        end
      end
      def obj.assert_complete
        raise "Called too few times" if @times < 2
      end

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: Encoding::UTF_8,
        internal_encoding: Encoding::UTF_16LE,
        encoding_opts: {newline: :universal}
      )
      -> { io.read_char }.should raise_error(Encoding::InvalidByteSequenceError)
      obj.assert_complete
    end

    it "raises Encoding::UndefinedConversionError when a character cannot be transcoded" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      # HACK:
      # Mspec mocks are not able to mutate arguments, but that is necessary for
      # #read when the buffer argument is not nil as will be the case here.
      # Emulate peforming a short read.  The checks on the results of the read
      # operations on the BufferedIO instance will serve as validation that the
      # method was called.
      def obj.read(length, buffer: nil, buffer_offset: 0)
        content = "🍣".b
        buffer[buffer_offset, content.bytesize] = content
        content.bytesize
      end

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: Encoding::UTF_8,
        internal_encoding: Encoding::Windows_31J,
        encoding_opts: {newline: :universal}
      )
      -> { io.read_char }.should raise_error(Encoding::UndefinedConversionError)
    end

    describe "with an incomplete character in the internal buffer" do
      it "returns invalid characters composed of bytes from the internal buffer when the stream is ended" do
        char_int = "🍣".encode(Encoding::UTF_16LE)
        obj = mock("io")
        obj.should_receive(:readable?).and_return(true)
        obj.should_receive(:read).at_least(1).and_raise(EOFError)

        io = IO::LikeHelpers::CharacterIO.new(
          IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
          external_encoding: Encoding::UTF_8,
          internal_encoding: Encoding::UTF_16LE,
          encoding_opts: {newline: :universal}
        )
        io.unread(char_int.b[0..-2])
        io.read_char.should == String.new("\x3C\xD8").force_encoding(Encoding::UTF_16LE)
        io.read_char.should == String.new("\x63").force_encoding(Encoding::UTF_16LE)
      end

      it "returns the next character composed of bytes that are invalid in the internal encoding from the internal buffer" do
        char_int = "🍣".encode(Encoding::UTF_16LE)
        obj = mock("io")
        obj.should_receive(:readable?).and_return(true)
        # HACK:
        # Mspec mocks are not able to mutate arguments, but that is necessary
        # for #read when the buffer argument is not nil as will be the case
        # here.  Emulate peforming a short read.  The checks on the results of
        # the read operations on the BufferedIO instance will serve as
        # validation that the method was called.
        def obj.read(length, buffer: nil, buffer_offset: 0)
          @times ||= 0
          @times += 1
          if @times == 1
            content = "🍣".b
            buffer[buffer_offset, content.bytesize] = content
            content.bytesize
          else
            raise EOFError
          end
        end
        def obj.assert_complete
          raise "Called too few times" if @times < 2
        end

        io = IO::LikeHelpers::CharacterIO.new(
          IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
          external_encoding: Encoding::UTF_8,
          internal_encoding: Encoding::UTF_16LE,
          encoding_opts: {newline: :universal}
        )
        io.unread(char_int.b[0..-2])
        io.read_char.should == String.new("\x3C\xD8").force_encoding(Encoding::UTF_16LE)
        io.read_char.should == String.new("\x63\x3C").force_encoding(Encoding::UTF_16LE)
        io.read_char.should == String.new("\xD8\x63").force_encoding(Encoding::UTF_16LE)
        io.read_char.should == String.new("\xDF").force_encoding(Encoding::UTF_16LE)
        obj.assert_complete
      end
    end
  end

  describe "when not transcoding and without the universal newline decorator set" do
    it "raises IOError if the stream is not readable" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(false)

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: Encoding::UTF_8
      )
      lambda { io.read_char }.should raise_error(IOError)
    end

    it "raises EOFError if called at the end of the stream" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      obj.should_receive(:read).and_raise(EOFError)

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: Encoding::UTF_8
      )
      -> { io.read_char }.should raise_error(EOFError)
    end

    it "returns the next character from the stream" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      def obj.read(length, buffer: nil, buffer_offset: 0)
        buffer[buffer_offset] = "a".b
        1
      end

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: Encoding::UTF_8
      )
      io.read_char.should == "a"
    end

    it "returns the character pushed onto the internal buffer" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: Encoding::UTF_8
      )
      io.unread("a".b)
      io.read_char.should == "a"
    end

    it "returns the next character encoded with the default external encoding if not set for the stream and the stream is writable" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      def obj.read(length, buffer: nil, buffer_offset: 0)
        buffer[buffer_offset] = "a".b
        1
      end

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
      )
      begin
        default_external = Encoding.default_external
        Encoding.default_external = Encoding::ISO_8859_1

        io.read_char.encoding.should == Encoding::ISO_8859_1
      ensure
        Encoding.default_external = default_external
      end
    end

    it "returns the next character encoded with the default external encoding if not set for the stream and the stream is not writable" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      def obj.read(length, buffer: nil, buffer_offset: 0)
        buffer[buffer_offset] = "a".b
        1
      end

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false)
      )
      begin
        default_external = Encoding.default_external
        Encoding.default_external = Encoding::ISO_8859_1

        io.read_char.encoding.should == Encoding::ISO_8859_1
      ensure
        Encoding.default_external = default_external
      end
    end

    it "returns the character pushed onto the stream" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: Encoding::UTF_8
      )
      io.unread("a".b)
      io.read_char.should == "a"
    end

    it "omits newline handling" do
      cr = "\r".b
      nl = "\n".b
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      # HACK:
      # Mspec mocks are not able to mutate arguments, but that is necessary for
      # #read when the buffer argument is not nil as will be the case here.
      # Emulate peforming a short read.  The checks on the results of the read
      # operations on the BufferedIO instance will serve as validation that the
      # method was called.
      def obj.read(length, buffer: nil, buffer_offset: 0)
        content = "\r\r\n\n".b
        buffer[buffer_offset, content.bytesize] = content
        content.bytesize
      end

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: Encoding::UTF_8
      )
      io.read_char.should == cr.encode(Encoding::UTF_8)
      io.read_char.should == cr.encode(Encoding::UTF_8)
      io.read_char.should == nl.encode(Encoding::UTF_8)
      io.read_char.should == nl.encode(Encoding::UTF_8)
    end

    describe "with an incomplete character in the internal buffer" do
      it "returns the next character composed of bytes from the internal buffer and the stream" do
        char = "🍣"
        obj = mock("io")
        obj.should_receive(:readable?).and_return(true)
        # HACK:
        # Mspec mocks are not able to mutate arguments, but that is necessary
        # for #read when the buffer argument is not nil as will be the case
        # here.  Emulate peforming a short read.  The checks on the results of
        # the read operations on the BufferedIO instance will serve as
        # validation that the method was called.
        def obj.read(length, buffer: nil, buffer_offset: 0)
          content = "🍣".b[-1]
          buffer[buffer_offset, content.bytesize] = content
          content.bytesize
        end

        io = IO::LikeHelpers::CharacterIO.new(
          IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
          external_encoding: Encoding::UTF_8
        )
        io.unread(char.b[0..-2])
        io.read_char.should == char
      end

      it "returns an invalid character when the next byte from the stream cannot complete it" do
        char = "🍣"
        obj = mock("io")
        obj.should_receive(:readable?).and_return(true)
        # HACK:
        # Mspec mocks are not able to mutate arguments, but that is necessary
        # for #read when the buffer argument is not nil as will be the case
        # here.  Emulate peforming a short read.  The checks on the results of
        # the read operations on the BufferedIO instance will serve as
        # validation that the method was called.
        def obj.read(length, buffer: nil, buffer_offset: 0)
          content = "🍣".b
          buffer[buffer_offset, content.bytesize] = content
          content.bytesize
        end

        io = IO::LikeHelpers::CharacterIO.new(
          IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
          external_encoding: Encoding::UTF_8
        )
        io.unread(char.b[0..-2])
        io.read_char.should == char.b[0].force_encoding(Encoding::UTF_8)
        io.read_char.should == char.b[1].force_encoding(Encoding::UTF_8)
        io.read_char.should == char.b[2].force_encoding(Encoding::UTF_8)
        io.read_char.should == char
      end

      it "returns an invalid character when the stream is ended" do
        char = "🍣"
        obj = mock("io")
        obj.should_receive(:readable?).and_return(true)
        obj.should_receive(:read).at_least(1).and_raise(EOFError)

        io = IO::LikeHelpers::CharacterIO.new(
          IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
          external_encoding: Encoding::UTF_8
        )
        io.unread(char.b[0..-2])
        io.read_char.should == char.b[0].force_encoding(Encoding::UTF_8)
        io.read_char.should == char.b[1].force_encoding(Encoding::UTF_8)
        io.read_char.should == char.b[2].force_encoding(Encoding::UTF_8)
      end
    end
  end

  describe "when not transcoding while the universal newline decorator is set" do
    it "raises IOError if the stream is not readable" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(false)

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: Encoding::UTF_8,
        encoding_opts: {newline: :universal}
      )
      lambda { io.read_char }.should raise_error(IOError)
    end

    it "raises EOFError if called at the end of the stream" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      obj.should_receive(:read).and_raise(EOFError)

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: Encoding::UTF_8,
        encoding_opts: {newline: :universal}
      )
      -> { io.read_char }.should raise_error(EOFError)
    end

    it "returns the next character from the stream" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      def obj.read(length, buffer: nil, buffer_offset: 0)
        buffer[buffer_offset] = "a".b
        1
      end

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: Encoding::UTF_8,
        encoding_opts: {newline: :universal}
      )
      io.read_char.should == "a"
    end

    it "returns the character pushed onto the internal buffer" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: Encoding::UTF_8,
        encoding_opts: {newline: :universal}
      )
      io.unread("a".b)
      io.read_char.should == "a"
    end

    it "obeys the universal newline decorator" do
      cr = "\r".b
      nl = "\n".b
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      # HACK:
      # Mspec mocks are not able to mutate arguments, but that is necessary for
      # #read when the buffer argument is not nil as will be the case here.
      # Emulate peforming a short read.  The checks on the results of the read
      # operations on the BufferedIO instance will serve as validation that the
      # method was called.
      def obj.read(length, buffer: nil, buffer_offset: 0)
        content = "\r\r\n\n".b
        buffer[buffer_offset, content.bytesize] = content
        content.bytesize
      end

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: Encoding::UTF_8,
        encoding_opts: {newline: :universal}
      )
      io.read_char.should == nl.encode(Encoding::UTF_8)
      io.read_char.should == nl.encode(Encoding::UTF_8)
      io.read_char.should == nl.encode(Encoding::UTF_8)
    end

    it "converts carriage return at end of file to newline" do
      nl = "\n".b

      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      # HACK:
      # Mspec mocks do not seem able to define a method that intermixes
      # returning results and raising exceptions.  Define such a method here and
      # a way to check that it was called enough times.
      def obj.read(length, buffer: nil, buffer_offset: 0)
        @times ||= 0
        @times += 1
        if @times == 1
          content = "\r".b
          buffer[buffer_offset, content.bytesize] = content
          content.bytesize
        else
          raise EOFError
        end
      end
      def obj.assert_complete
        raise "Called too few times" if @times < 2
      end

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: Encoding::UTF_8,
        encoding_opts: {newline: :universal}
      )
      io.read_char.should == nl.encode(Encoding::UTF_8)
      obj.assert_complete
    end

    describe "with an incomplete character in the internal buffer" do
      it "returns the next character composed of bytes from the internal buffer and the stream" do
        char = "🍣"
        obj = mock("io")
        obj.should_receive(:readable?).and_return(true)
        # HACK:
        # Mspec mocks are not able to mutate arguments, but that is necessary
        # for #read when the buffer argument is not nil as will be the case
        # here.  Emulate peforming a short read.  The checks on the results of
        # the read operations on the BufferedIO instance will serve as
        # validation that the method was called.
        def obj.read(length, buffer: nil, buffer_offset: 0)
          content = "🍣".b[-1]
          buffer[buffer_offset, content.bytesize] = content
          content.bytesize
        end

        io = IO::LikeHelpers::CharacterIO.new(
          IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
          external_encoding: Encoding::UTF_8,
          encoding_opts: {newline: :universal}
        )
        io.unread(char.b[0..-2])
        io.read_char.should == char
      end

      it "returns an invalid character when the next byte from the stream cannot complete it" do
        char = "🍣"
        obj = mock("io")
        obj.should_receive(:readable?).and_return(true)
        # HACK:
        # Mspec mocks are not able to mutate arguments, but that is necessary
        # for #read when the buffer argument is not nil as will be the case
        # here.  Emulate peforming a short read.  The checks on the results of
        # the read operations on the BufferedIO instance will serve as
        # validation that the method was called.
        def obj.read(length, buffer: nil, buffer_offset: 0)
          content = "🍣".b
          buffer[buffer_offset, content.bytesize] = content
          content.bytesize
        end

        io = IO::LikeHelpers::CharacterIO.new(
          IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
          external_encoding: Encoding::UTF_8,
          encoding_opts: {newline: :universal}
        )
        io.unread(char.b[0..-2])
        io.read_char.should == char.b[0].force_encoding(Encoding::UTF_8)
        io.read_char.should == char.b[1].force_encoding(Encoding::UTF_8)
        io.read_char.should == char.b[2].force_encoding(Encoding::UTF_8)
        io.read_char.should == char
      end

      it "returns an invalid character when the stream is ended" do
        char = "🍣"
        obj = mock("io")
        obj.should_receive(:readable?).and_return(true)
        obj.should_receive(:read).at_least(1).and_raise(EOFError)

        io = IO::LikeHelpers::CharacterIO.new(
          IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
          external_encoding: Encoding::UTF_8,
          encoding_opts: {newline: :universal}
        )
        io.unread(char.b[0..-2])
        io.read_char.should == char.b[0].force_encoding(Encoding::UTF_8)
        io.read_char.should == char.b[1].force_encoding(Encoding::UTF_8)
        io.read_char.should == char.b[2].force_encoding(Encoding::UTF_8)
      end
    end
  end

  describe "when not transcoding when external encoding is not set while the universal newline decorator is set" do
    it "raises IOError if the stream is not readable" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(false)

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: nil,
        encoding_opts: {newline: :universal}
      )
      lambda { io.read_char }.should raise_error(IOError)
    end

    it "raises EOFError if called at the end of the stream" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      obj.should_receive(:read).and_raise(EOFError)

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: nil,
        encoding_opts: {newline: :universal}
      )
      -> { io.read_char }.should raise_error(EOFError)
    end

    it "returns the next character from the stream" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      def obj.read(length, buffer: nil, buffer_offset: 0)
        buffer[buffer_offset] = "a".b
        1
      end

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: nil,
        encoding_opts: {newline: :universal}
      )
      io.read_char.should == "a"
    end

    it "returns the character pushed onto the internal buffer" do
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: nil,
        encoding_opts: {newline: :universal}
      )
      io.unread("a".b)
      io.read_char.should == "a"
    end

    it "ignores the universal newline decorator" do
      cr = "\r".b
      nl = "\n".b
      obj = mock("io")
      obj.should_receive(:readable?).and_return(true)
      # HACK:
      # Mspec mocks are not able to mutate arguments, but that is necessary for
      # #read when the buffer argument is not nil as will be the case here.
      # Emulate peforming a short read.  The checks on the results of the read
      # operations on the BufferedIO instance will serve as validation that the
      # method was called.
      def obj.read(length, buffer: nil, buffer_offset: 0)
        content = "\r\r\n\n".b
        buffer[buffer_offset, content.bytesize] = content
        content.bytesize
      end

      io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
        external_encoding: nil,
        encoding_opts: {newline: :universal}
      )
      io.read_char.should == cr.encode(Encoding::UTF_8)
      io.read_char.should == cr.encode(Encoding::UTF_8)
      io.read_char.should == nl.encode(Encoding::UTF_8)
      io.read_char.should == nl.encode(Encoding::UTF_8)
    end

    describe "with an incomplete character in the internal buffer" do
      it "returns the next character composed of bytes from the internal buffer and the stream" do
        char = "🍣"
        obj = mock("io")
        obj.should_receive(:readable?).and_return(true)
        # HACK:
        # Mspec mocks are not able to mutate arguments, but that is necessary
        # for #read when the buffer argument is not nil as will be the case
        # here.  Emulate peforming a short read.  The checks on the results of
        # the read operations on the BufferedIO instance will serve as
        # validation that the method was called.
        def obj.read(length, buffer: nil, buffer_offset: 0)
          content = "🍣".b[-1]
          buffer[buffer_offset, content.bytesize] = content
          content.bytesize
        end

        io = IO::LikeHelpers::CharacterIO.new(
          IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
          external_encoding: nil,
          encoding_opts: {newline: :universal}
        )
        io.unread(char.b[0..-2])
        io.read_char.should == char
      end

      it "returns an invalid character when the next byte from the stream cannot complete it" do
        char = "🍣"
        obj = mock("io")
        obj.should_receive(:readable?).and_return(true)
        # HACK:
        # Mspec mocks are not able to mutate arguments, but that is necessary
        # for #read when the buffer argument is not nil as will be the case
        # here.  Emulate peforming a short read.  The checks on the results of
        # the read operations on the BufferedIO instance will serve as
        # validation that the method was called.
        def obj.read(length, buffer: nil, buffer_offset: 0)
          content = "🍣".b
          buffer[buffer_offset, content.bytesize] = content
          content.bytesize
        end

        io = IO::LikeHelpers::CharacterIO.new(
          IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
          external_encoding: nil,
          encoding_opts: {newline: :universal}
        )
        io.unread(char.b[0..-2])
        io.read_char.should == char.b[0].force_encoding(Encoding::UTF_8)
        io.read_char.should == char.b[1].force_encoding(Encoding::UTF_8)
        io.read_char.should == char.b[2].force_encoding(Encoding::UTF_8)
        io.read_char.should == char
      end

      it "returns an invalid character when the stream is ended" do
        char = "🍣"
        obj = mock("io")
        obj.should_receive(:readable?).and_return(true)
        obj.should_receive(:read).at_least(1).and_raise(EOFError)

        io = IO::LikeHelpers::CharacterIO.new(
          IO::LikeHelpers::BufferedIO.new(obj, autoclose: false),
          external_encoding: nil,
          encoding_opts: {newline: :universal}
        )
        io.unread(char.b[0..-2])
        io.read_char.should == char.b[0].force_encoding(Encoding::UTF_8)
        io.read_char.should == char.b[1].force_encoding(Encoding::UTF_8)
        io.read_char.should == char.b[2].force_encoding(Encoding::UTF_8)
      end
    end
  end
end

# vim: ts=2 sw=2 et
