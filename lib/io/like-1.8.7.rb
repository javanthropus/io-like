require 'enumerator'         # in case used under Ruby < v1.8.7
require 'io/like-1.8.6'

class IO # :nodoc:
  # This module provides most of the basic input and output functions of IO
  # objects as implemented in Ruby version 1.8.7.  Its use is supported on all
  # versions of Ruby.  See the general documentation of IO::Like for a
  # description of how to create a class capable of using this module.
  #
  # Include this module explicitely rather than IO::Like if the including class
  # should always behave like Ruby 1.8.7 IO no matter what version of Ruby is
  # running the class.
  module Like_1_8_7
    include IO::Like_1_8_6

    # call-seq:
    #   ios.bytes            -> anEnumerator
    #
    # Calls #each_byte without a block and returns the resulting
    # Enumerable::Enumerator instance.
    def bytes
      each_byte
    end

    # call-seq:
    #   ios.each_byte { |byte| block } -> ios
    #   ios.each_byte        -> anEnumerator
    #
    # Reads each byte (0..255) from the stream using #getbyte and calls the
    # given block once for each byte, passing the byte as an argument.
    #
    # <b>NOTE:</b> This method ignores Errno::EAGAIN and Errno::EINTR raised by
    # #unbuffered_read.  Therefore, this method always blocks.  Aside from that
    # exception and the conversion of EOFError results into +nil+ results, this
    # method will also raise the same errors and block at the same times as
    # #unbuffered_read.
    def each_byte(&b)
      block_given? ?
        super(&b) :
        Enumerable::Enumerator.new(self, :each_byte)
    end

    # call-seq:
    #   ios.each_char { |char| block } -> ios
    #   ios.each_char        -> anEnumerator
    #
    # Reads each character from the stream and calls the given block once for
    # each character, passing the character as an argument.  The character is a
    # single or multi-byte string depending on the character to be read and the
    # setting of <tt>$KCODE</tt>.
    #
    # When called without a block, returns an instance of Enumerable::Enumerator
    # which will iterate over each character in the same manner.
    #
    # <b>NOTE:</b> This method ignores Errno::EAGAIN and Errno::EINTR raised by
    # #unbuffered_read.  Therefore, this method always blocks.  Aside from that
    # exception and the conversion of EOFError results into +nil+ results, this
    # method will also raise the same errors and block at the same times as
    # #unbuffered_read.
    def each_char
      unless block_given? then
        return Enumerable::Enumerator.new(self, :each_char)
      end

      while (byte = getbyte) do
        char = byte.chr
        # The first byte of the character was already read, so read 1 less than
        # the total number of bytes for the character to get the rest.
        char_len(byte).downto(2) do
          byte = getbyte
          break if byte.nil?
          char << byte.chr
        end
        yield(char)
      end
      self
    end

    # _chars_ is just an alias for _eachchar_ in Ruby 1.8.7.
    alias :chars :each_char

    # call-seq:
    #   ios.each_line(sep_string = $/) { |line| block } -> ios
    #   ios.each_line(sep_string = $/) -> anEnumerator
    #   ios.each(sep_string = $/) { |line| block } -> ios
    #   ios.each(sep_string = $/) -> anEnumerator
    #
    # Reads each line from the stream using #gets and calls the given block once
    # for each line, passing the line as an argument.
    #
    # <b>NOTE:</b> When _sep_string_ is not +nil+, this method ignores
    # Errno::EAGAIN and Errno::EINTR raised by #unbuffered_read.  Therefore,
    # this method always blocks.  Aside from that exception and the conversion
    # of EOFError results into +nil+ results, this method will also raise the
    # same errors and block at the same times as #unbuffered_read.
    def each_line(sep_string = $/, &b)
      block_given? ?
        super(sep_string, &b) :
        Enumerable::Enumerator.new(self, :each_line, sep_string)
    end
    alias :each :each_line

    # _getbyte_ is just an alias for _getc_ in Ruby 1.8.7.
    alias :getbyte :getc

    # call-seq:
    #   ios.lines(sep_string = $/) -> anEnumerator
    #
    # Calls #each_line without a block and returns the resulting
    # Enumerable::Enumerator instance.
    def lines(sep_string = $/)
      each_line(sep_string)
    end

    # _readbyte_ is just an alias for _readchar_ in Ruby 1.8.7.
    alias :readbyte :readchar

    private

    MBCTYPE_EUC = [
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 3,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
      2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
      2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
      2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
      2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
      2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1
    ]

    MBCTYPE_SJIS = [
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
      2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
      2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1
    ]

    MBCTYPE_UTF8 = [
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
      2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
      3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
      4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 1, 1,
    ]

    MBCTYPE_ASCII = [
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    ]

    # Given _byte_ which represents the first byte of a possibly multi-byte
    # character, returns the total number of bytes for the character based on
    # the setting of $KCODE.
    def char_len(byte)
      # Get the first byte of $KCODE on all versions of Ruby up to 1.9.1.
      kcode = $KCODE.respond_to?(:getbyte) ? $KCODE.getbyte(0) : $KCODE[0]

      # This is essentially what the Ruby guts do to find the right lookup
      # table.
      case kcode
      when ?E, ?e
        MBCTYPE_EUC[byte]
      when ?S, ?s
        MBCTYPE_SJIS[byte]
      when ?U, ?u
        MBCTYPE_UTF8[byte]
      else # when ?N, ?n, ?A, ?a
        MBCTYPE_ASCII[byte]
      end
    end
  end
end

# vim: ts=2 sw=2 et
