# -*- encoding: utf-8 -*-
require_relative '../../spec_helper'

describe "IO::Like.new" do
  it "raises ArgumentError when newline is invalid" do
    obj = mock("io")
    -> { IO::Like.new(obj, newline: :foo) }.should raise_error(ArgumentError)
  end

  ruby_version_is '2.7' do
    it "sets the external encoding using a BOM when external_encoding starts with \"bom|\"" do
      r, w = IO.pipe
      w.write("\xFE\xFFabc")
      w.close

      IO::Like.open(
        IO::LikeHelpers::BufferedIO.new(IO::LikeHelpers::IOWrapper.new(r)),
        binmode: true, external_encoding: 'bom|us-ascii'
      ) do |io|
        io.external_encoding.should == Encoding::UTF_16BE
      end
    end

    it "uses fallback encoding when external_encoding starts with \"bom|\" when BOM is not available" do
      r, w = IO.pipe
      w.write("abc")
      w.close

      IO::Like.open(
        IO::LikeHelpers::BufferedIO.new(IO::LikeHelpers::IOWrapper.new(r)),
        binmode: true, external_encoding: 'bom|us-ascii'
      ) do |io|
        io.external_encoding.should == Encoding::US_ASCII
      end
    end
  end
end

# vim: ts=2 sw=2 et
