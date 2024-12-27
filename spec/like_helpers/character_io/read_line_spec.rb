# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

require 'io/like_helpers/buffered_io'
require 'io/like_helpers/character_io'
require 'io/like_helpers/io_wrapper'

describe "IO::LikeHelpers::CharacterIO#read_line" do
  describe "when transcoding without the universal newline decorator set" do
    describe "from ASCII compatible to ASCII incompatible encodings" do
      before :each do
        @separator = $/.encode(Encoding::UTF_16LE)
        @file = File.new(fixture(__FILE__, 'lines.txt'))
        @io = IO::LikeHelpers::CharacterIO.new(
          IO::LikeHelpers::BufferedIO.new(
            IO::LikeHelpers::IOWrapper.new(
              @file
            )
          ),
          external_encoding: Encoding::UTF_8,
          internal_encoding: Encoding::UTF_16LE
        )
      end

      after :each do
        @file.close
      end

      it "returns the next line in the stream" do
        @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_16LE)
        @io.read_line(separator: @separator).should == "ʻO kēia ka paukū mua, ʻōlelo hoʻokahi.\n".encode(Encoding::UTF_16LE)
        @io.read_line(separator: @separator).should == "Esta é a frase dois.\n".encode(Encoding::UTF_16LE)
        @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_16LE)
        @io.read_line(separator: @separator).should == "यह पैराग्राफ दो, वाक्य एक है।\n".encode(Encoding::UTF_16LE)
        @io.read_line(separator: @separator).should == "그리고 이것은 두 번째 문장입니다.\n".encode(Encoding::UTF_16LE)
        @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_16LE)
        @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_16LE)
        @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_16LE)
        @io.read_line(separator: @separator).should == "Η τρίτη παράγραφος αρχίζει και τελειώνει εδώ.\n".encode(Encoding::UTF_16LE)
        @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_16LE)
        @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_16LE)
        @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_16LE)
      end

      it "returns the next paragraph in the stream" do
        @io.read_line(separator: "\n\n", discard_newlines: true).should == "ʻO kēia ka paukū mua, ʻōlelo hoʻokahi.\nEsta é a frase dois.\n\n".encode(Encoding::UTF_16LE)
        @io.read_line(separator: "\n\n", discard_newlines: true).should == "यह पैराग्राफ दो, वाक्य एक है।\n그리고 이것은 두 번째 문장입니다.\n\n".encode(Encoding::UTF_16LE)
        @io.read_line(separator: "\n\n", discard_newlines: true).should == "Η τρίτη παράγραφος αρχίζει και τελειώνει εδώ.\n\n".encode(Encoding::UTF_16LE)
      end

      it "returns all remaining text in the stream" do
        @io.read_line(separator: nil).should == File.read(fixture(__FILE__, 'lines.txt'), encoding: 'utf-8:utf-16le')
      end

      it "raises EOFError at the end of the stream" do
        @io.read_line(separator: nil)
        -> { @io.read_line(separator: nil) }.should raise_error(EOFError)
      end

      it "raises IOError on a closed stream" do
        @file.close
        -> { @io.read_line(separator: nil) }.should raise_error(IOError)
      end

      describe "when passed a non-nil limit" do
        it "reads less than limit bytes if the separator is found first" do
          @io.read_line(separator: @separator, limit: 10).should == "\n".encode(Encoding::UTF_16LE)
        end

        it "reads exactly limit bytes when the limit exactly bounds the last character" do
          @io.read_line(separator: @separator, limit: 10).should == "\n".encode(Encoding::UTF_16LE)
          @io.read_line(separator: @separator, limit: 10).should == "ʻO kē".encode(Encoding::UTF_16LE)
        end

        it "reads more than limit bytes to avoid splitting the last character" do
          @io.read_line(separator: @separator, limit: 10).should == "\n".encode(Encoding::UTF_16LE)
          @io.read_line(separator: @separator, limit: 9).should == "ʻO kē".encode(Encoding::UTF_16LE)
        end

        it "returns an empty string when passed 0 as a limit" do
          @io.read_line(separator: @separator, limit: 0).should == ""
          @io.read_line(separator: @separator, limit: 0).encoding.should == Encoding::UTF_16LE
        end
      end

      describe "when using a Regexp as a separator" do
        before :each do
          @separator = Regexp.new(String.new("\n").encode(Encoding::UTF_16LE).b)
        end

        it "returns the next line in the stream" do
          @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_16LE)
          @io.read_line(separator: @separator).should == "ʻO kēia ka paukū mua, ʻōlelo hoʻokahi.\n".encode(Encoding::UTF_16LE)
          @io.read_line(separator: @separator).should == "Esta é a frase dois.\n".encode(Encoding::UTF_16LE)
          @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_16LE)
          @io.read_line(separator: @separator).should == "यह पैराग्राफ दो, वाक्य एक है।\n".encode(Encoding::UTF_16LE)
          @io.read_line(separator: @separator).should == "그리고 이것은 두 번째 문장입니다.\n".encode(Encoding::UTF_16LE)
          @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_16LE)
          @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_16LE)
          @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_16LE)
          @io.read_line(separator: @separator).should == "Η τρίτη παράγραφος αρχίζει και τελειώνει εδώ.\n".encode(Encoding::UTF_16LE)
          @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_16LE)
          @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_16LE)
          @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_16LE)
        end

        describe "when passed a non-nil limit" do
          it "reads less than limit bytes if the separator is found first" do
            @io.read_line(separator: @separator, limit: 10).should == "\n".encode(Encoding::UTF_16LE)
          end

          it "reads exactly limit bytes when the limit exactly bounds the last character" do
            @io.read_line(separator: @separator, limit: 10).should == "\n".encode(Encoding::UTF_16LE)
            @io.read_line(separator: @separator, limit: 10).should == "ʻO kē".encode(Encoding::UTF_16LE)
          end

          it "reads more than limit bytes to avoid splitting the last character" do
            @io.read_line(separator: @separator, limit: 10).should == "\n".encode(Encoding::UTF_16LE)
            @io.read_line(separator: @separator, limit: 9).should == "ʻO kē".encode(Encoding::UTF_16LE)
          end

          it "returns an empty string when passed 0 as a limit" do
            @io.read_line(separator: @separator, limit: 0).should == ""
            @io.read_line(separator: @separator, limit: 0).encoding.should == Encoding::UTF_16LE
          end
        end
      end
    end

    describe "from ASCII incompatible to ASCII compatible encodings" do
      before :each do
        @separator = $/.encode(Encoding::UTF_8)
        @file = File.new(fixture(__FILE__, 'lines-utf-16le.txt'))
        @io = IO::LikeHelpers::CharacterIO.new(
          IO::LikeHelpers::BufferedIO.new(
            IO::LikeHelpers::IOWrapper.new(
              @file
            )
          ),
          external_encoding: Encoding::UTF_16LE,
          internal_encoding: Encoding::UTF_8
        )
      end

      after :each do
        @file.close
      end

      it "returns the next line in the stream" do
        @io.read_line(separator: @separator).should == "\n"
        @io.read_line(separator: @separator).should == "ʻO kēia ka paukū mua, ʻōlelo hoʻokahi.\n"
        @io.read_line(separator: @separator).should == "Esta é a frase dois.\n"
        @io.read_line(separator: @separator).should == "\n"
        @io.read_line(separator: @separator).should == "यह पैराग्राफ दो, वाक्य एक है।\n"
        @io.read_line(separator: @separator).should == "그리고 이것은 두 번째 문장입니다.\n"
        @io.read_line(separator: @separator).should == "\n"
        @io.read_line(separator: @separator).should == "\n"
        @io.read_line(separator: @separator).should == "\n"
        @io.read_line(separator: @separator).should == "Η τρίτη παράγραφος αρχίζει και τελειώνει εδώ.\n"
        @io.read_line(separator: @separator).should == "\n"
        @io.read_line(separator: @separator).should == "\n"
        @io.read_line(separator: @separator).should == "\n"
      end

      it "returns the next paragraph in the stream" do
        @io.read_line(separator: "\n\n", discard_newlines: true).should == "ʻO kēia ka paukū mua, ʻōlelo hoʻokahi.\nEsta é a frase dois.\n\n"
        @io.read_line(separator: "\n\n", discard_newlines: true).should == "यह पैराग्राफ दो, वाक्य एक है।\n그리고 이것은 두 번째 문장입니다.\n\n"
        @io.read_line(separator: "\n\n", discard_newlines: true).should == "Η τρίτη παράγραφος αρχίζει και τελειώνει εδώ.\n\n"
      end

      it "returns all remaining text in the stream" do
        @io.read_line(separator: nil).should == File.read(fixture(__FILE__, 'lines-utf-16le.txt'), encoding: 'utf-16le:utf-8')
      end

      it "raises EOFError at the end of the stream" do
        @io.read_line(separator: nil)
        -> { @io.read_line(separator: nil) }.should raise_error(EOFError)
      end

      it "raises IOError on a closed stream" do
        @file.close
        -> { @io.read_line(separator: nil) }.should raise_error(IOError)
      end

      describe "when passed a non-nil limit" do
        it "reads less than limit bytes if the separator is found first" do
          @io.read_line(separator: @separator, limit: 7).should == "\n"
        end

        it "reads exactly limit bytes when the limit exactly bounds the last character" do
          @io.read_line(separator: @separator, limit: 7).should == "\n"
          @io.read_line(separator: @separator, limit: 7).should == "ʻO kē"
        end

        it "reads more than limit bytes to avoid splitting the last character" do
          @io.read_line(separator: @separator, limit: 7).should == "\n"
          @io.read_line(separator: @separator, limit: 6).should == "ʻO kē"
        end

        it "returns an empty string when passed 0 as a limit" do
          @io.read_line(separator: @separator, limit: 0).should == ""
          @io.read_line(separator: @separator, limit: 0).encoding.should == Encoding::UTF_8
        end
      end

      describe "when using a Regexp as a separator" do
        before :each do
          @separator = Regexp.new(String.new("\n").b)
        end

        it "returns the next line in the stream" do
          @io.read_line(separator: @separator).should == "\n"
          @io.read_line(separator: @separator).should == "ʻO kēia ka paukū mua, ʻōlelo hoʻokahi.\n"
          @io.read_line(separator: @separator).should == "Esta é a frase dois.\n"
          @io.read_line(separator: @separator).should == "\n"
          @io.read_line(separator: @separator).should == "यह पैराग्राफ दो, वाक्य एक है।\n"
          @io.read_line(separator: @separator).should == "그리고 이것은 두 번째 문장입니다.\n"
          @io.read_line(separator: @separator).should == "\n"
          @io.read_line(separator: @separator).should == "\n"
          @io.read_line(separator: @separator).should == "\n"
          @io.read_line(separator: @separator).should == "Η τρίτη παράγραφος αρχίζει και τελειώνει εδώ.\n"
          @io.read_line(separator: @separator).should == "\n"
          @io.read_line(separator: @separator).should == "\n"
          @io.read_line(separator: @separator).should == "\n"
        end

        describe "when passed a non-nil limit" do
          it "reads less than limit bytes if the separator is found first" do
            @io.read_line(separator: @separator, limit: 7).should == "\n"
          end

          it "reads exactly limit bytes when the limit exactly bounds the last character" do
            @io.read_line(separator: @separator, limit: 7).should == "\n"
            @io.read_line(separator: @separator, limit: 7).should == "ʻO kē"
          end

          it "reads more than limit bytes to avoid splitting the last character" do
            @io.read_line(separator: @separator, limit: 7).should == "\n"
            @io.read_line(separator: @separator, limit: 6).should == "ʻO kē"
          end

          it "returns an empty string when passed 0 as a limit" do
            @io.read_line(separator: @separator, limit: 0).should == ""
            @io.read_line(separator: @separator, limit: 0).encoding.should == Encoding::UTF_8
          end
        end
      end
    end

    describe "from ASCII incompatible to ASCII incompatible encodings" do
      before :each do
        @separator = $/.encode(Encoding::UTF_32LE)
        @file = File.new(fixture(__FILE__, 'lines-utf-16le.txt'))
        @io = IO::LikeHelpers::CharacterIO.new(
          IO::LikeHelpers::BufferedIO.new(
            IO::LikeHelpers::IOWrapper.new(
              @file
            )
          ),
          external_encoding: Encoding::UTF_16LE,
          internal_encoding: Encoding::UTF_32LE
        )
      end

      after :each do
        @file.close
      end

      it "returns the next line in the stream" do
        @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_32LE)
        @io.read_line(separator: @separator).should == "ʻO kēia ka paukū mua, ʻōlelo hoʻokahi.\n".encode(Encoding::UTF_32LE)
        @io.read_line(separator: @separator).should == "Esta é a frase dois.\n".encode(Encoding::UTF_32LE)
        @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_32LE)
        @io.read_line(separator: @separator).should == "यह पैराग्राफ दो, वाक्य एक है।\n".encode(Encoding::UTF_32LE)
        @io.read_line(separator: @separator).should == "그리고 이것은 두 번째 문장입니다.\n".encode(Encoding::UTF_32LE)
        @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_32LE)
        @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_32LE)
        @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_32LE)
        @io.read_line(separator: @separator).should == "Η τρίτη παράγραφος αρχίζει και τελειώνει εδώ.\n".encode(Encoding::UTF_32LE)
        @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_32LE)
        @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_32LE)
        @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_32LE)
      end

      it "returns the next paragraph in the stream" do
        @io.read_line(separator: "\n\n", discard_newlines: true).should == "ʻO kēia ka paukū mua, ʻōlelo hoʻokahi.\nEsta é a frase dois.\n\n".encode(Encoding::UTF_32LE)
        @io.read_line(separator: "\n\n", discard_newlines: true).should == "यह पैराग्राफ दो, वाक्य एक है।\n그리고 이것은 두 번째 문장입니다.\n\n".encode(Encoding::UTF_32LE)
        @io.read_line(separator: "\n\n", discard_newlines: true).should == "Η τρίτη παράγραφος αρχίζει και τελειώνει εδώ.\n\n".encode(Encoding::UTF_32LE)
      end

      it "returns all remaining text in the stream" do
        @io.read_line(separator: nil).should == File.read(fixture(__FILE__, 'lines-utf-16le.txt'), encoding: 'utf-16le:utf-32le')
      end

      it "raises EOFError at the end of the stream" do
        @io.read_line(separator: nil)
        -> { @io.read_line(separator: nil) }.should raise_error(EOFError)
      end

      it "raises IOError on a closed stream" do
        @file.close
        -> { @io.read_line(separator: nil) }.should raise_error(IOError)
      end

      describe "when passed a non-nil limit" do
        it "reads less than limit bytes if the separator is found first" do
          @io.read_line(separator: @separator, limit: 20).should == "\n".encode(Encoding::UTF_32LE)
        end

        it "reads exactly limit bytes when the limit exactly bounds the last character" do
          @io.read_line(separator: @separator, limit: 20).should == "\n".encode(Encoding::UTF_32LE)
          @io.read_line(separator: @separator, limit: 20).should == "ʻO kē".encode(Encoding::UTF_32LE)
        end

        it "reads more than limit bytes to avoid splitting the last character" do
          @io.read_line(separator: @separator, limit: 20).should == "\n".encode(Encoding::UTF_32LE)
          @io.read_line(separator: @separator, limit: 19).should == "ʻO kē".encode(Encoding::UTF_32LE)
        end

        it "returns an empty string when passed 0 as a limit" do
          @io.read_line(separator: @separator, limit: 0).should == "".encode(Encoding::UTF_32LE)
          @io.read_line(separator: @separator, limit: 0).encoding.should == Encoding::UTF_32LE
        end
      end

      describe "when using a Regexp as a separator" do
        before :each do
          @separator = Regexp.new(String.new("\n").encode(Encoding::UTF_32LE).b)
        end

        it "returns the next line in the stream" do
          @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_32LE)
          @io.read_line(separator: @separator).should == "ʻO kēia ka paukū mua, ʻōlelo hoʻokahi.\n".encode(Encoding::UTF_32LE)
          @io.read_line(separator: @separator).should == "Esta é a frase dois.\n".encode(Encoding::UTF_32LE)
          @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_32LE)
          @io.read_line(separator: @separator).should == "यह पैराग्राफ दो, वाक्य एक है।\n".encode(Encoding::UTF_32LE)
          @io.read_line(separator: @separator).should == "그리고 이것은 두 번째 문장입니다.\n".encode(Encoding::UTF_32LE)
          @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_32LE)
          @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_32LE)
          @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_32LE)
          @io.read_line(separator: @separator).should == "Η τρίτη παράγραφος αρχίζει και τελειώνει εδώ.\n".encode(Encoding::UTF_32LE)
          @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_32LE)
          @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_32LE)
          @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_32LE)
        end

        describe "when passed a non-nil limit" do
          it "reads less than limit bytes if the separator is found first" do
            @io.read_line(separator: @separator, limit: 20).should == "\n".encode(Encoding::UTF_32LE)
          end

          it "reads exactly limit bytes when the limit exactly bounds the last character" do
            @io.read_line(separator: @separator, limit: 20).should == "\n".encode(Encoding::UTF_32LE)
            @io.read_line(separator: @separator, limit: 20).should == "ʻO kē".encode(Encoding::UTF_32LE)
          end

          it "reads more than limit bytes to avoid splitting the last character" do
            @io.read_line(separator: @separator, limit: 20).should == "\n".encode(Encoding::UTF_32LE)
            @io.read_line(separator: @separator, limit: 19).should == "ʻO kē".encode(Encoding::UTF_32LE)
          end

          it "returns an empty string when passed 0 as a limit" do
            @io.read_line(separator: @separator, limit: 0).should == ""
            @io.read_line(separator: @separator, limit: 0).encoding.should == Encoding::UTF_32LE
          end
        end
      end
    end
  end

  describe "when transcoding while the universal newline decorator set" do
    describe "from ASCII compatible to ASCII incompatible encodings" do
      before :each do
        @separator = $/.encode(Encoding::UTF_16LE)
        @file = File.new(fixture(__FILE__, 'lines-crlf.txt'))
        @io = IO::LikeHelpers::CharacterIO.new(
          IO::LikeHelpers::BufferedIO.new(
            IO::LikeHelpers::IOWrapper.new(
              @file
            )
          ),
          encoding_opts: {newline: :universal},
          external_encoding: Encoding::UTF_8,
          internal_encoding: Encoding::UTF_16LE
        )
      end

      after :each do
        @file.close
      end

      it "returns the next line in the stream" do
        @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_16LE)
        @io.read_line(separator: @separator).should == "ʻO kēia ka paukū mua, ʻōlelo hoʻokahi.\n".encode(Encoding::UTF_16LE)
        @io.read_line(separator: @separator).should == "Esta é a frase dois.\n".encode(Encoding::UTF_16LE)
        @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_16LE)
        @io.read_line(separator: @separator).should == "यह पैराग्राफ दो, वाक्य एक है।\n".encode(Encoding::UTF_16LE)
        @io.read_line(separator: @separator).should == "그리고 이것은 두 번째 문장입니다.\n".encode(Encoding::UTF_16LE)
        @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_16LE)
        @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_16LE)
        @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_16LE)
        @io.read_line(separator: @separator).should == "Η τρίτη παράγραφος αρχίζει και τελειώνει εδώ.\n".encode(Encoding::UTF_16LE)
        @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_16LE)
        @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_16LE)
        @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_16LE)
      end

      it "returns the next paragraph in the stream" do
        @io.read_line(separator: "\n\n", discard_newlines: true).should == "ʻO kēia ka paukū mua, ʻōlelo hoʻokahi.\nEsta é a frase dois.\n\n".encode(Encoding::UTF_16LE)
        @io.read_line(separator: "\n\n", discard_newlines: true).should == "यह पैराग्राफ दो, वाक्य एक है।\n그리고 이것은 두 번째 문장입니다.\n\n".encode(Encoding::UTF_16LE)
        @io.read_line(separator: "\n\n", discard_newlines: true).should == "Η τρίτη παράγραφος αρχίζει και τελειώνει εδώ.\n\n".encode(Encoding::UTF_16LE)
      end

      it "returns all remaining text in the stream" do
        @io.read_line(separator: nil).should == File.read(fixture(__FILE__, 'lines-crlf.txt'), encoding: 'utf-8:utf-16le', newline: :universal)
      end

      it "raises EOFError at the end of the stream" do
        @io.read_line(separator: nil)
        -> { @io.read_line(separator: nil) }.should raise_error(EOFError)
      end

      it "raises IOError on a closed stream" do
        @file.close
        -> { @io.read_line(separator: nil) }.should raise_error(IOError)
      end

      describe "when passed a non-nil limit" do
        it "reads less than limit bytes if the separator is found first" do
          @io.read_line(separator: @separator, limit: 10).should == "\n".encode(Encoding::UTF_16LE)
        end

        it "reads exactly limit bytes when the limit exactly bounds the last character" do
          @io.read_line(separator: @separator, limit: 10).should == "\n".encode(Encoding::UTF_16LE)
          @io.read_line(separator: @separator, limit: 10).should == "ʻO kē".encode(Encoding::UTF_16LE)
        end

        it "reads more than limit bytes to avoid splitting the last character" do
          @io.read_line(separator: @separator, limit: 10).should == "\n".encode(Encoding::UTF_16LE)
          @io.read_line(separator: @separator, limit: 9).should == "ʻO kē".encode(Encoding::UTF_16LE)
        end

        it "returns an empty string when passed 0 as a limit" do
          @io.read_line(separator: @separator, limit: 0).should == ""
          @io.read_line(separator: @separator, limit: 0).encoding.should == Encoding::UTF_16LE
        end
      end

      describe "when using a Regexp as a separator" do
        before :each do
          @separator = Regexp.new(String.new("\n").encode(Encoding::UTF_16LE).b)
        end

        it "returns the next line in the stream" do
          @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_16LE)
          @io.read_line(separator: @separator).should == "ʻO kēia ka paukū mua, ʻōlelo hoʻokahi.\n".encode(Encoding::UTF_16LE)
          @io.read_line(separator: @separator).should == "Esta é a frase dois.\n".encode(Encoding::UTF_16LE)
          @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_16LE)
          @io.read_line(separator: @separator).should == "यह पैराग्राफ दो, वाक्य एक है।\n".encode(Encoding::UTF_16LE)
          @io.read_line(separator: @separator).should == "그리고 이것은 두 번째 문장입니다.\n".encode(Encoding::UTF_16LE)
          @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_16LE)
          @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_16LE)
          @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_16LE)
          @io.read_line(separator: @separator).should == "Η τρίτη παράγραφος αρχίζει και τελειώνει εδώ.\n".encode(Encoding::UTF_16LE)
          @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_16LE)
          @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_16LE)
          @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_16LE)
        end

        describe "when passed a non-nil limit" do
          it "reads less than limit bytes if the separator is found first" do
            @io.read_line(separator: @separator, limit: 10).should == "\n".encode(Encoding::UTF_16LE)
          end

          it "reads exactly limit bytes when the limit exactly bounds the last character" do
            @io.read_line(separator: @separator, limit: 10).should == "\n".encode(Encoding::UTF_16LE)
            @io.read_line(separator: @separator, limit: 10).should == "ʻO kē".encode(Encoding::UTF_16LE)
          end

          it "reads more than limit bytes to avoid splitting the last character" do
            @io.read_line(separator: @separator, limit: 10).should == "\n".encode(Encoding::UTF_16LE)
            @io.read_line(separator: @separator, limit: 9).should == "ʻO kē".encode(Encoding::UTF_16LE)
          end

          it "returns an empty string when passed 0 as a limit" do
            @io.read_line(separator: @separator, limit: 0).should == ""
            @io.read_line(separator: @separator, limit: 0).encoding.should == Encoding::UTF_16LE
          end
        end
      end
    end

    describe "from ASCII incompatible to ASCII compatible encodings" do
      before :each do
        @separator = $/.encode(Encoding::UTF_8)
        @file = File.new(fixture(__FILE__, 'lines-utf-16le_crlf.txt'))
        @io = IO::LikeHelpers::CharacterIO.new(
          IO::LikeHelpers::BufferedIO.new(
            IO::LikeHelpers::IOWrapper.new(
              @file
            )
          ),
          encoding_opts: {newline: :universal},
          external_encoding: Encoding::UTF_16LE,
          internal_encoding: Encoding::UTF_8
        )
      end

      after :each do
        @file.close
      end

      it "returns the next line in the stream" do
        @io.read_line(separator: @separator).should == "\n"
        @io.read_line(separator: @separator).should == "ʻO kēia ka paukū mua, ʻōlelo hoʻokahi.\n"
        @io.read_line(separator: @separator).should == "Esta é a frase dois.\n"
        @io.read_line(separator: @separator).should == "\n"
        @io.read_line(separator: @separator).should == "यह पैराग्राफ दो, वाक्य एक है।\n"
        @io.read_line(separator: @separator).should == "그리고 이것은 두 번째 문장입니다.\n"
        @io.read_line(separator: @separator).should == "\n"
        @io.read_line(separator: @separator).should == "\n"
        @io.read_line(separator: @separator).should == "\n"
        @io.read_line(separator: @separator).should == "Η τρίτη παράγραφος αρχίζει και τελειώνει εδώ.\n"
        @io.read_line(separator: @separator).should == "\n"
        @io.read_line(separator: @separator).should == "\n"
        @io.read_line(separator: @separator).should == "\n"
      end

      it "returns the next paragraph in the stream" do
        @io.read_line(separator: "\n\n", discard_newlines: true).should == "ʻO kēia ka paukū mua, ʻōlelo hoʻokahi.\nEsta é a frase dois.\n\n"
        @io.read_line(separator: "\n\n", discard_newlines: true).should == "यह पैराग्राफ दो, वाक्य एक है।\n그리고 이것은 두 번째 문장입니다.\n\n"
        @io.read_line(separator: "\n\n", discard_newlines: true).should == "Η τρίτη παράγραφος αρχίζει και τελειώνει εδώ.\n\n"
      end

      it "returns all remaining text in the stream" do
        @io.read_line(separator: nil).should == File.read(fixture(__FILE__, 'lines-utf-16le_crlf.txt'), encoding: 'utf-16le:utf-8', newline: :universal)
      end

      it "raises EOFError at the end of the stream" do
        @io.read_line(separator: nil)
        -> { @io.read_line(separator: nil) }.should raise_error(EOFError)
      end

      it "raises IOError on a closed stream" do
        @file.close
        -> { @io.read_line(separator: nil) }.should raise_error(IOError)
      end

      describe "when passed a non-nil limit" do
        it "reads less than limit bytes if the separator is found first" do
          @io.read_line(separator: @separator, limit: 7).should == "\n"
        end

        it "reads exactly limit bytes when the limit exactly bounds the last character" do
          @io.read_line(separator: @separator, limit: 7).should == "\n"
          @io.read_line(separator: @separator, limit: 7).should == "ʻO kē"
        end

        it "reads more than limit bytes to avoid splitting the last character" do
          @io.read_line(separator: @separator, limit: 7).should == "\n"
          @io.read_line(separator: @separator, limit: 6).should == "ʻO kē"
        end

        it "returns an empty string when passed 0 as a limit" do
          @io.read_line(separator: @separator, limit: 0).should == ""
          @io.read_line(separator: @separator, limit: 0).encoding.should == Encoding::UTF_8
        end
      end

      describe "when using a Regexp as a separator" do
        before :each do
          @separator = Regexp.new(String.new("\n").b)
        end

        it "returns the next line in the stream" do
          @io.read_line(separator: @separator).should == "\n"
          @io.read_line(separator: @separator).should == "ʻO kēia ka paukū mua, ʻōlelo hoʻokahi.\n"
          @io.read_line(separator: @separator).should == "Esta é a frase dois.\n"
          @io.read_line(separator: @separator).should == "\n"
          @io.read_line(separator: @separator).should == "यह पैराग्राफ दो, वाक्य एक है।\n"
          @io.read_line(separator: @separator).should == "그리고 이것은 두 번째 문장입니다.\n"
          @io.read_line(separator: @separator).should == "\n"
          @io.read_line(separator: @separator).should == "\n"
          @io.read_line(separator: @separator).should == "\n"
          @io.read_line(separator: @separator).should == "Η τρίτη παράγραφος αρχίζει και τελειώνει εδώ.\n"
          @io.read_line(separator: @separator).should == "\n"
          @io.read_line(separator: @separator).should == "\n"
          @io.read_line(separator: @separator).should == "\n"
        end

        describe "when passed a non-nil limit" do
          it "reads less than limit bytes if the separator is found first" do
            @io.read_line(separator: @separator, limit: 7).should == "\n"
          end

          it "reads exactly limit bytes when the limit exactly bounds the last character" do
            @io.read_line(separator: @separator, limit: 7).should == "\n"
            @io.read_line(separator: @separator, limit: 7).should == "ʻO kē"
          end

          it "reads more than limit bytes to avoid splitting the last character" do
            @io.read_line(separator: @separator, limit: 7).should == "\n"
            @io.read_line(separator: @separator, limit: 6).should == "ʻO kē"
          end

          it "returns an empty string when passed 0 as a limit" do
            @io.read_line(separator: @separator, limit: 0).should == ""
            @io.read_line(separator: @separator, limit: 0).encoding.should == Encoding::UTF_8
          end
        end
      end
    end

    describe "from ASCII incompatible to ASCII incompatible encodings" do
      before :each do
        @separator = $/.encode(Encoding::UTF_32LE)
        @file = File.new(fixture(__FILE__, 'lines-utf-16le_crlf.txt'))
        @io = IO::LikeHelpers::CharacterIO.new(
          IO::LikeHelpers::BufferedIO.new(
            IO::LikeHelpers::IOWrapper.new(
              @file
            )
          ),
          encoding_opts: {newline: :universal},
          external_encoding: Encoding::UTF_16LE,
          internal_encoding: Encoding::UTF_32LE
        )
      end

      after :each do
        @file.close
      end

      it "returns the next line in the stream" do
        @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_32LE)
        @io.read_line(separator: @separator).should == "ʻO kēia ka paukū mua, ʻōlelo hoʻokahi.\n".encode(Encoding::UTF_32LE)
        @io.read_line(separator: @separator).should == "Esta é a frase dois.\n".encode(Encoding::UTF_32LE)
        @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_32LE)
        @io.read_line(separator: @separator).should == "यह पैराग्राफ दो, वाक्य एक है।\n".encode(Encoding::UTF_32LE)
        @io.read_line(separator: @separator).should == "그리고 이것은 두 번째 문장입니다.\n".encode(Encoding::UTF_32LE)
        @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_32LE)
        @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_32LE)
        @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_32LE)
        @io.read_line(separator: @separator).should == "Η τρίτη παράγραφος αρχίζει και τελειώνει εδώ.\n".encode(Encoding::UTF_32LE)
        @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_32LE)
        @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_32LE)
        @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_32LE)
      end

      it "returns the next paragraph in the stream" do
        @io.read_line(separator: "\n\n", discard_newlines: true).should == "ʻO kēia ka paukū mua, ʻōlelo hoʻokahi.\nEsta é a frase dois.\n\n".encode(Encoding::UTF_32LE)
        @io.read_line(separator: "\n\n", discard_newlines: true).should == "यह पैराग्राफ दो, वाक्य एक है।\n그리고 이것은 두 번째 문장입니다.\n\n".encode(Encoding::UTF_32LE)
        @io.read_line(separator: "\n\n", discard_newlines: true).should == "Η τρίτη παράγραφος αρχίζει και τελειώνει εδώ.\n\n".encode(Encoding::UTF_32LE)
      end

      it "returns all remaining text in the stream" do
        @io.read_line(separator: nil).should == File.read(fixture(__FILE__, 'lines-utf-16le.txt'), encoding: 'utf-16le:utf-32le')
      end

      it "raises EOFError at the end of the stream" do
        @io.read_line(separator: nil)
        -> { @io.read_line(separator: nil) }.should raise_error(EOFError)
      end

      it "raises IOError on a closed stream" do
        @file.close
        -> { @io.read_line(separator: nil) }.should raise_error(IOError)
      end

      describe "when passed a non-nil limit" do
        it "reads less than limit bytes if the separator is found first" do
          @io.read_line(separator: @separator, limit: 20).should == "\n".encode(Encoding::UTF_32LE)
        end

        it "reads exactly limit bytes when the limit exactly bounds the last character" do
          @io.read_line(separator: @separator, limit: 20).should == "\n".encode(Encoding::UTF_32LE)
          @io.read_line(separator: @separator, limit: 20).should == "ʻO kē".encode(Encoding::UTF_32LE)
        end

        it "reads more than limit bytes to avoid splitting the last character" do
          @io.read_line(separator: @separator, limit: 20).should == "\n".encode(Encoding::UTF_32LE)
          @io.read_line(separator: @separator, limit: 19).should == "ʻO kē".encode(Encoding::UTF_32LE)
        end

        it "returns an empty string when passed 0 as a limit" do
          @io.read_line(separator: @separator, limit: 0).should == "".encode(Encoding::UTF_32LE)
          @io.read_line(separator: @separator, limit: 0).encoding.should == Encoding::UTF_32LE
        end
      end

      describe "when using a Regexp as a separator" do
        before :each do
          @separator = Regexp.new(String.new("\n").encode(Encoding::UTF_32LE).b)
        end

        it "returns the next line in the stream" do
          @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_32LE)
          @io.read_line(separator: @separator).should == "ʻO kēia ka paukū mua, ʻōlelo hoʻokahi.\n".encode(Encoding::UTF_32LE)
          @io.read_line(separator: @separator).should == "Esta é a frase dois.\n".encode(Encoding::UTF_32LE)
          @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_32LE)
          @io.read_line(separator: @separator).should == "यह पैराग्राफ दो, वाक्य एक है।\n".encode(Encoding::UTF_32LE)
          @io.read_line(separator: @separator).should == "그리고 이것은 두 번째 문장입니다.\n".encode(Encoding::UTF_32LE)
          @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_32LE)
          @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_32LE)
          @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_32LE)
          @io.read_line(separator: @separator).should == "Η τρίτη παράγραφος αρχίζει και τελειώνει εδώ.\n".encode(Encoding::UTF_32LE)
          @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_32LE)
          @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_32LE)
          @io.read_line(separator: @separator).should == "\n".encode(Encoding::UTF_32LE)
        end

        describe "when passed a non-nil limit" do
          it "reads less than limit bytes if the separator is found first" do
            @io.read_line(separator: @separator, limit: 20).should == "\n".encode(Encoding::UTF_32LE)
          end

          it "reads exactly limit bytes when the limit exactly bounds the last character" do
            @io.read_line(separator: @separator, limit: 20).should == "\n".encode(Encoding::UTF_32LE)
            @io.read_line(separator: @separator, limit: 20).should == "ʻO kē".encode(Encoding::UTF_32LE)
          end

          it "reads more than limit bytes to avoid splitting the last character" do
            @io.read_line(separator: @separator, limit: 20).should == "\n".encode(Encoding::UTF_32LE)
            @io.read_line(separator: @separator, limit: 19).should == "ʻO kē".encode(Encoding::UTF_32LE)
          end

          it "returns an empty string when passed 0 as a limit" do
            @io.read_line(separator: @separator, limit: 0).should == ""
            @io.read_line(separator: @separator, limit: 0).encoding.should == Encoding::UTF_32LE
          end
        end
      end
    end
  end

  describe "when not transcoding and without the universal newline decorator set" do
    before :each do
      @separator = $/.encode(Encoding::UTF_8)
      @file = File.new(fixture(__FILE__, 'lines.txt'))
      @io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(
          IO::LikeHelpers::IOWrapper.new(
            @file
          )
        ),
        external_encoding: Encoding::UTF_8
      )
    end

    after :each do
      @file.close
    end

    it "returns the next line in the stream" do
      @io.read_line(separator: @separator).should == "\n"
      @io.read_line(separator: @separator).should == "ʻO kēia ka paukū mua, ʻōlelo hoʻokahi.\n"
      @io.read_line(separator: @separator).should == "Esta é a frase dois.\n"
      @io.read_line(separator: @separator).should == "\n"
      @io.read_line(separator: @separator).should == "यह पैराग्राफ दो, वाक्य एक है।\n"
      @io.read_line(separator: @separator).should == "그리고 이것은 두 번째 문장입니다.\n"
      @io.read_line(separator: @separator).should == "\n"
      @io.read_line(separator: @separator).should == "\n"
      @io.read_line(separator: @separator).should == "\n"
      @io.read_line(separator: @separator).should == "Η τρίτη παράγραφος αρχίζει και τελειώνει εδώ.\n"
      @io.read_line(separator: @separator).should == "\n"
      @io.read_line(separator: @separator).should == "\n"
      @io.read_line(separator: @separator).should == "\n"
    end

    it "returns the next paragraph in the stream" do
      @io.read_line(separator: "\n\n", discard_newlines: true).should == "ʻO kēia ka paukū mua, ʻōlelo hoʻokahi.\nEsta é a frase dois.\n\n"
      @io.read_line(separator: "\n\n", discard_newlines: true).should == "यह पैराग्राफ दो, वाक्य एक है।\n그리고 이것은 두 번째 문장입니다.\n\n"
      @io.read_line(separator: "\n\n", discard_newlines: true).should == "Η τρίτη παράγραφος αρχίζει και τελειώνει εδώ.\n\n"
    end

    it "returns all remaining text in the stream" do
      @io.read_line(separator: nil).should == File.read(fixture(__FILE__, 'lines.txt'), encoding: Encoding::UTF_8)
    end

    it "raises EOFError at the end of the stream" do
      @io.read_line(separator: nil)
      -> { @io.read_line(separator: nil) }.should raise_error(EOFError)
    end

    it "raises IOError on a closed stream" do
      @file.close
      -> { @io.read_line(separator: nil) }.should raise_error(IOError)
    end

    describe "when passed a non-nil limit" do
      it "reads less than limit bytes if the separator is found first" do
        @io.read_line(separator: @separator, limit: 7).should == "\n"
      end

      it "reads exactly limit bytes when the limit exactly bounds the last character" do
        @io.read_line(separator: @separator, limit: 7).should == "\n"
        @io.read_line(separator: @separator, limit: 7).should == "ʻO kē"
      end

      it "reads more than limit bytes to avoid splitting the last character" do
        @io.read_line(separator: @separator, limit: 7).should == "\n"
        @io.read_line(separator: @separator, limit: 6).should == "ʻO kē"
      end

      it "returns an empty string when passed 0 as a limit" do
        @io.read_line(separator: @separator, limit: 0).should == ""
        @io.read_line(separator: @separator, limit: 0).encoding.should == Encoding::UTF_8
      end
    end

    describe "when using a Regexp as a separator" do
      before :each do
        @separator = Regexp.new(String.new("\n").b)
      end

      it "returns the next line in the stream" do
        @io.read_line(separator: @separator).should == "\n"
        @io.read_line(separator: @separator).should == "ʻO kēia ka paukū mua, ʻōlelo hoʻokahi.\n"
        @io.read_line(separator: @separator).should == "Esta é a frase dois.\n"
        @io.read_line(separator: @separator).should == "\n"
        @io.read_line(separator: @separator).should == "यह पैराग्राफ दो, वाक्य एक है।\n"
        @io.read_line(separator: @separator).should == "그리고 이것은 두 번째 문장입니다.\n"
        @io.read_line(separator: @separator).should == "\n"
        @io.read_line(separator: @separator).should == "\n"
        @io.read_line(separator: @separator).should == "\n"
        @io.read_line(separator: @separator).should == "Η τρίτη παράγραφος αρχίζει και τελειώνει εδώ.\n"
        @io.read_line(separator: @separator).should == "\n"
        @io.read_line(separator: @separator).should == "\n"
        @io.read_line(separator: @separator).should == "\n"
      end

      describe "when passed a non-nil limit" do
        it "reads less than limit bytes if the separator is found first" do
          @io.read_line(separator: @separator, limit: 7).should == "\n"
        end

        it "reads exactly limit bytes when the limit exactly bounds the last character" do
          @io.read_line(separator: @separator, limit: 7).should == "\n"
          @io.read_line(separator: @separator, limit: 7).should == "ʻO kē"
        end

        it "reads more than limit bytes to avoid splitting the last character" do
          @io.read_line(separator: @separator, limit: 7).should == "\n"
          @io.read_line(separator: @separator, limit: 6).should == "ʻO kē"
        end

        it "returns an empty string when passed 0 as a limit" do
          @io.read_line(separator: @separator, limit: 0).should == ""
          @io.read_line(separator: @separator, limit: 0).encoding.should == Encoding::UTF_8
        end
      end
    end
  end

  describe "when not transcoding while the universal newline decorator is set" do
    before :each do
      @separator = $/.encode(Encoding::UTF_8)
      @file = File.new(fixture(__FILE__, 'lines-crlf.txt'))
      @io = IO::LikeHelpers::CharacterIO.new(
        IO::LikeHelpers::BufferedIO.new(
          IO::LikeHelpers::IOWrapper.new(
            @file
          )
        ),
        encoding_opts: {newline: :universal},
        external_encoding: Encoding::UTF_8
      )
    end

    after :each do
      @file.close
    end

    it "returns the next line in the stream" do
      @io.read_line(separator: @separator).should == "\n"
      @io.read_line(separator: @separator).should == "ʻO kēia ka paukū mua, ʻōlelo hoʻokahi.\n"
      @io.read_line(separator: @separator).should == "Esta é a frase dois.\n"
      @io.read_line(separator: @separator).should == "\n"
      @io.read_line(separator: @separator).should == "यह पैराग्राफ दो, वाक्य एक है।\n"
      @io.read_line(separator: @separator).should == "그리고 이것은 두 번째 문장입니다.\n"
      @io.read_line(separator: @separator).should == "\n"
      @io.read_line(separator: @separator).should == "\n"
      @io.read_line(separator: @separator).should == "\n"
      @io.read_line(separator: @separator).should == "Η τρίτη παράγραφος αρχίζει και τελειώνει εδώ.\n"
      @io.read_line(separator: @separator).should == "\n"
      @io.read_line(separator: @separator).should == "\n"
      @io.read_line(separator: @separator).should == "\n"
    end

    it "returns the next paragraph in the stream" do
      @io.read_line(separator: "\n\n", discard_newlines: true).should == "ʻO kēia ka paukū mua, ʻōlelo hoʻokahi.\nEsta é a frase dois.\n\n"
      @io.read_line(separator: "\n\n", discard_newlines: true).should == "यह पैराग्राफ दो, वाक्य एक है।\n그리고 이것은 두 번째 문장입니다.\n\n"
      @io.read_line(separator: "\n\n", discard_newlines: true).should == "Η τρίτη παράγραφος αρχίζει και τελειώνει εδώ.\n\n"
    end

    it "returns all remaining text in the stream" do
      @io.read_line(separator: nil).should == File.read(fixture(__FILE__, 'lines-crlf.txt'), encoding: Encoding::UTF_8, newline: :universal)
    end

    it "raises EOFError at the end of the stream" do
      @io.read_line(separator: nil)
      -> { @io.read_line(separator: nil) }.should raise_error(EOFError)
    end

    it "raises IOError on a closed stream" do
      @file.close
      -> { @io.read_line(separator: nil) }.should raise_error(IOError)
    end

    describe "when passed a non-nil limit" do
      it "reads less than limit bytes if the separator is found first" do
        @io.read_line(separator: @separator, limit: 7).should == "\n"
      end

      it "reads exactly limit bytes when the limit exactly bounds the last character" do
        @io.read_line(separator: @separator, limit: 7).should == "\n"
        @io.read_line(separator: @separator, limit: 7).should == "ʻO kē"
      end

      it "reads more than limit bytes to avoid splitting the last character" do
        @io.read_line(separator: @separator, limit: 7).should == "\n"
        @io.read_line(separator: @separator, limit: 6).should == "ʻO kē"
      end

      it "returns an empty string when passed 0 as a limit" do
        @io.read_line(separator: @separator, limit: 0).should == ""
        @io.read_line(separator: @separator, limit: 0).encoding.should == Encoding::UTF_8
      end
    end

    describe "when using a Regexp as a separator" do
      before :each do
        @separator = Regexp.new(String.new("\n").b)
      end

      it "returns the next line in the stream" do
        @io.read_line(separator: @separator).should == "\n"
        @io.read_line(separator: @separator).should == "ʻO kēia ka paukū mua, ʻōlelo hoʻokahi.\n"
        @io.read_line(separator: @separator).should == "Esta é a frase dois.\n"
        @io.read_line(separator: @separator).should == "\n"
        @io.read_line(separator: @separator).should == "यह पैराग्राफ दो, वाक्य एक है।\n"
        @io.read_line(separator: @separator).should == "그리고 이것은 두 번째 문장입니다.\n"
        @io.read_line(separator: @separator).should == "\n"
        @io.read_line(separator: @separator).should == "\n"
        @io.read_line(separator: @separator).should == "\n"
        @io.read_line(separator: @separator).should == "Η τρίτη παράγραφος αρχίζει και τελειώνει εδώ.\n"
        @io.read_line(separator: @separator).should == "\n"
        @io.read_line(separator: @separator).should == "\n"
        @io.read_line(separator: @separator).should == "\n"
      end

      describe "when passed a non-nil limit" do
        it "reads less than limit bytes if the separator is found first" do
          @io.read_line(separator: @separator, limit: 7).should == "\n"
        end

        it "reads exactly limit bytes when the limit exactly bounds the last character" do
          @io.read_line(separator: @separator, limit: 7).should == "\n"
          @io.read_line(separator: @separator, limit: 7).should == "ʻO kē"
        end

        it "reads more than limit bytes to avoid splitting the last character" do
          @io.read_line(separator: @separator, limit: 7).should == "\n"
          @io.read_line(separator: @separator, limit: 6).should == "ʻO kē"
        end

        it "returns an empty string when passed 0 as a limit" do
          @io.read_line(separator: @separator, limit: 0).should == ""
          @io.read_line(separator: @separator, limit: 0).encoding.should == Encoding::UTF_8
        end
      end
    end
  end
end

# vim: ts=2 sw=2 et
