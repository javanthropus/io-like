# encoding: UTF-8

require File.dirname(__FILE__) + '/../fixtures/classes'

describe :io_like__write, :shared => true do
  it "raises IOError on read-only stream if writing more than zero bytes" do
    lambda do
      IOSpecs.readonly_io.send(@method, "abcde")
    end.should raise_error(IOError)
  end

  it "raises IOError on closed stream if writing more than zero bytes" do
    lambda do
      IOSpecs.closed_io.send(@method, "abcde")
    end.should raise_error(IOError)
  end
end
