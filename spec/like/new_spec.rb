# -*- encoding: utf-8 -*-
require_relative '../../spec_helper'

describe "IO::Like.new" do
  before :each do
    @fname = tmp("IO__Like_new")
    touch @fname
    @delegate = IO::LikeHelpers::IOWrapper.new(File.new(@fname, "r+"))
  end

  after :each do
    @delegate.close
    rm_r @fname
  end

  it "raises ArgumentError if the first delegate is nil" do
    -> { IO::Like.new(nil) }.should raise_error(ArgumentError)
  end

  it "raises ArgumentError if the second delegate is nil" do
    -> { IO::Like.new(@delegate, nil) }.should raise_error(ArgumentError)
  end

  it "sets the autoclose flag" do
    IO::Like.open(@delegate, autoclose: false) {}
    @delegate.closed?.should be_false
    IO::Like.open(@delegate, autoclose: true) {}
    @delegate.closed?.should be_true
  end

  it "sets binary mode to the binmode argument" do
    IO::Like.open(@delegate, autoclose: false, binmode: true) do |io|
      io.binmode?.should be_true
    end
    IO::Like.open(@delegate, autoclose: false, binmode: false) do |io|
      io.binmode?.should be_false
    end
  end

  it "sets sync mode to the sync argument" do
    IO::Like.open(@delegate, autoclose: false, sync: true) do |io|
      io.sync.should be_true
    end
    IO::Like.open(@delegate, autoclose: false, sync: false) do |io|
      io.sync.should be_false
    end
  end

  it "sets pid attribute to the pid argument" do
    IO::Like.open(@delegate, autoclose: false, pid: 1234) do |io|
      io.pid.should == 1234
    end
    IO::Like.open(@delegate, autoclose: false, pid: nil) do |io|
      io.pid.should be_nil
    end
  end

  it "uses a custom pipeline class if provided" do
    pipeline_class = mock("pipeline")
    pipeline_class.should_receive(:new).with(@delegate, autoclose: true).
      and_return(IO::LikeHelpers::Pipeline.new(@delegate, autoclose: true))
    IO::Like.open(@delegate, pipeline_class: pipeline_class) {}
  end

  it "sets the external encoding to the encoding argument" do
    IO::Like.open(@delegate, encoding: "iso-8859-1") do |io|
      io.external_encoding.should == Encoding::ISO_8859_1
      io.internal_encoding.should be_nil
    end
  end

  it "sets the external and internal encodings to the encoding argument" do
    IO::Like.open(@delegate, encoding: "iso-8859-1:iso-8859-2") do |io|
      io.external_encoding.should == Encoding::ISO_8859_1
      io.internal_encoding.should == Encoding::ISO_8859_2
    end
  end

  it "sets the external encoding to the external_encoding argument" do
    IO::Like.open(@delegate, external_encoding: "iso-8859-1") do |io|
      io.external_encoding.should == Encoding::ISO_8859_1
      io.internal_encoding.should be_nil
    end
  end

  it "sets the internal encoding to the internal_encoding argument" do
    IO::Like.open(
      @delegate,
      external_encoding: "iso-8859-1",
      internal_encoding: "iso-8859-2"
    ) do |io|
      io.external_encoding.should == Encoding::ISO_8859_1
      io.internal_encoding.should == Encoding::ISO_8859_2
    end
  end

  it "sets the external encoding to Encoding.default_external when only internal_encoding is set" do
    IO::Like.open(@delegate, internal_encoding: 'utf-8') do |io|
      io.external_encoding.should == Encoding.default_external
    end
  end

  it "warns when encoding is used with external_encoding" do
    -> {
      IO::Like.new(@delegate, encoding: 'utf-8', external_encoding: 'utf-8')
    }.should complain(/Ignoring encoding parameter '.*': external_encoding is used/)
  end

  it "warns when encoding is used with internal_encoding" do
    -> {
      IO::Like.new(@delegate, encoding: 'utf-8', internal_encoding: 'utf-8')
    }.should complain(/Ignoring encoding parameter '.*': internal_encoding is used/)
  end

  it "raises ArgumentError when external_encoding is not a valid encoding" do
    -> {
      IO::Like.new(@delegate, external_encoding: 'invalid')
    }.should raise_error(ArgumentError)

    -> {
      IO::Like.new(@delegate, external_encoding: 'utf-8:utf-16le')
    }.should raise_error(ArgumentError)

    -> {
      IO::Like.new(@delegate, external_encoding: 'bom|utf-16le')
    }.should raise_error(ArgumentError)
  end

  ruby_version_is '2.7' do
    it "sets the external encoding using a BOM when encoding starts with \"bom|\"" do
      r, w = IO.pipe
      w.write("\xFE\xFFabc")
      w.close

      IO::Like.open(
        IO::LikeHelpers::IOWrapper.new(r),
        binmode: true, encoding: 'bom|us-ascii'
      ) do |io|
        io.external_encoding.should == Encoding::UTF_16BE
      end
    end

    it "uses fallback encoding when encoding starts with \"bom|\" when BOM is not available" do
      r, w = IO.pipe
      w.write("abc")
      w.close

      IO::Like.open(
        IO::LikeHelpers::IOWrapper.new(r),
        binmode: true, encoding: 'bom|us-ascii'
      ) do |io|
        io.external_encoding.should == Encoding::US_ASCII
      end
    end
  end
end

# vim: ts=2 sw=2 et
