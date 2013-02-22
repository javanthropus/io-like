# encoding: UTF-8
require File.dirname(__FILE__) + '/../fixtures/classes'

describe :io_like__each, :shared => true do

  it "raises IOError on write-only stream" do
    # method must have a block in order to raise the IOError.
    # MRI 1.8.7 returns enumerator if block is not provided.
    # See [ruby-core:16557].
    lambda do
      IOSpecs.writable_iowrapper do |iowrapper|
        iowrapper.send(@method) {}
      end
    end.should raise_error(IOError)
  end

end
