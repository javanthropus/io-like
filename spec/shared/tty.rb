# encoding: UTF-8

require File.dirname(__FILE__) + '/../fixtures/classes'

describe :io_like__tty, :shared => true do
  # IO::Like is never a TTY
  it "returns false if this stream is open" do
    io = mock_io_like
    io.stub!(:closed?).and_return(false)
    io.send(@method).should == false
  end
end
