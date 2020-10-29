# -*- encoding: utf-8 -*-
require_relative '../../spec_helper'

# These specs just make sure we are using wrapped objects.  Otherwise rubyspec
# will pass using normal IO and not really be testing IO::Like.
describe "IO::Like rubyspecs" do
  before(:each) do
    @fname = tmp("io-like.txt")
    touch(@fname)
  end

  after(:each) do
    rm_r @fname
  end

  it "should provide IO::Like for $stdout" do
    $stdout.should be_kind_of(IO::Like)
  end

  it "should provide IO::Like for $stderr" do
    $stderr.should be_kind_of(IO::Like)
  end

  it "should provide IO::Like for File.open" do
    f = File.open(@fname, "r+").should be_kind_of(IO::Like)
  end

  it "should provide IO::Like for File.open with a block" do
    File.open(@fname, "r+") do |f|
      f.should be_kind_of(IO::Like)
    end
  end

  it "should provide IO::Like for Object#open" do
    open(@fname, "r+").should be_kind_of(IO::Like)
  end

  it "should provide IO::Like for Object#open with block" do
    open(@fname) do |f|
      f.should be_kind_of(IO::Like)
    end
  end

  it "should provide IO::Like for #new_io" do
    new_io(@fname,"r+").should be_kind_of(IO::Like)
  end

  it "should provide IO::Like for IO.pipe" do
    r, w = IO.pipe
    r.should be_kind_of(IO::Like)
    w.should be_kind_of(IO::Like)
    r.close
    w.close
  end

  it "should provide IO::Like for IO.popen" do
    io = IO.popen('cat', 'r+')
    io.should be_kind_of(IO::Like)
    io.close
  end

  ruby_version_is "1.9" do
    it "should provide IO::Like for IO.pipe with block" do
      IO.pipe do |r, w|
        r.should be_kind_of(IO::Like)
        w.should be_kind_of(IO::Like)
      end
    end

    it "should provide IO::Like for IO.popen with block" do
      IO.popen('cat', 'r+') do |io|
        io.should be_kind_of(IO::Like)
      end
    end
  end
end

# vim: ts=2 sw=2 et
