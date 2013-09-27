# encoding: UTF-8

require File.dirname(__FILE__) + '/../rubyspec/spec_helper'

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

  it "should provide IOWrapper for File.open" do
    f = File.open(@fname, "r+").should be_kind_of(IOWrapper)
  end

  it "should provide IOWrapper for File.open with a block" do
    File.open(@fname, "r+") do |f|
      f.should be_kind_of(IOWrapper)
    end
  end

  it "should provide IOWrapper for Object#open" do
    open(@fname, "r+").should be_kind_of(IOWrapper)
  end

  it "should provide IOWrapper for Object#open with block" do
    open(@fname) do |f|
      f.should be_kind_of(IOWrapper)
    end
  end

  it "should provide IOWrapper for #new_io" do
    new_io(@fname,"r+").should be_kind_of(IOWrapper)
  end

  it "should provide IOWrapper for io.pipe" do
    r, w = IO.pipe
    r.should be_kind_of(IOWrapper)
    w.should be_kind_of(IOWrapper)
    r.close
    w.close
  end

  ruby_version_is "1.9" do
    it "should provide IOWrapper for io.pipe with block" do
      IO.pipe do |r, w|
        r.should be_kind_of(IOWrapper)
        w.should be_kind_of(IOWrapper)
      end
    end
  end
end
