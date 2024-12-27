# -*- encoding: utf-8 -*-
require_relative '../../../spec_helper'

describe "IO::LikeHelpers::DuplexedIO#dup" do
  describe "when not duplexed" do
    it "dups the delegate" do
      obj_dup = mock("io_dup")
      obj_dup.should_receive(:readable?).and_return(true)
      obj_dup.should_receive(:close).and_return(nil)
      obj = mock("io")
      obj.should_receive(:dup).and_return(obj_dup)
      io = IO::LikeHelpers::DuplexedIO.new(obj, autoclose: false).dup

      io.readable?.should be_true

      io.close
    end

    it "raises IOError when its delegate raises it" do
      obj = mock("io")
      obj.should_receive(:dup).and_raise(IOError.new('closed stream'))
      io = IO::LikeHelpers::DuplexedIO.new(obj, autoclose: false)
      -> { io.dup }.should raise_error(IOError, 'closed stream')
    end

    it "raises IOError if the stream is closed" do
      obj = mock("io")
      io = IO::LikeHelpers::DuplexedIO.new(obj, autoclose: false)
      io.close
      -> { io.dup }.should raise_error(IOError, 'closed stream')
    end

    it "sets the autoclose flag on the new stream" do
      obj_dup = mock("io_dup")
      obj_dup.should_receive(:close).and_return(nil).exactly(2)
      obj = mock("io")
      obj.should_receive(:dup).and_return(obj_dup).exactly(2)
      io = IO::LikeHelpers::DuplexedIO.new(obj, autoclose: false)

      io.autoclose = true
      io_dup = io.dup
      io_dup.autoclose?.should be_true
      io_dup.close

      io.autoclose = false
      io_dup = io.dup
      io_dup.autoclose?.should be_true
      io_dup.close
    end
  end

  describe "when duplexed" do
    it "dups both delegates" do
      obj_r_dup = mock("reader_io_dup")
      obj_r_dup.should_receive(:readable?).and_return(true)
      obj_r_dup.should_receive(:close).and_return(nil)
      obj_r = mock("reader_io")
      obj_r.should_receive(:dup).and_return(obj_r_dup)
      obj_w_dup = mock("writer_io_dup")
      obj_w_dup.should_receive(:writable?).and_return(true)
      obj_w_dup.should_receive(:close).and_return(nil)
      obj_w = mock("writer_io")
      obj_w.should_receive(:dup).and_return(obj_w_dup)
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false).dup

      io.readable?.should be_true
      io.writable?.should be_true

      io.close
    end

    it "dups only the reader if the write stream is closed" do
      obj_r_dup = mock("reader_io_dup")
      obj_r_dup.should_receive(:readable?).and_return(true)
      obj_r_dup.should_receive(:close).and_return(nil)
      obj_r = mock("reader_io")
      obj_r.should_receive(:dup).and_return(obj_r_dup)
      obj_w = mock("writer_io")
      obj_w.should_not_receive(:dup)
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.close_write
      io = io.dup

      io.readable?.should be_true
      io.writable?.should be_false

      io.close
    end

    it "dups only the writer if the read stream is closed" do
      obj_r = mock("reader_io")
      obj_r.should_not_receive(:dup)
      obj_w_dup = mock("writer_io_dup")
      obj_w_dup.should_receive(:writable?).and_return(true)
      obj_w_dup.should_receive(:close).and_return(nil)
      obj_w = mock("writer_io")
      obj_w.should_receive(:dup).and_return(obj_w_dup)
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      io.close_read
      io = io.dup

      io.readable?.should be_false
      io.writable?.should be_true

      io.close
    end

    it "raises IOError when the reader delegate raises it" do
      obj_r = mock("reader_io")
      obj_r.should_receive(:dup).and_raise(IOError.new('closed stream'))
      obj_w = mock("writer_io")
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      -> { io.dup }.should raise_error(IOError, 'closed stream')
    end

    it "raises IOError when the writer delegate raises it" do
      obj_r_dup = mock("reader_io_dup")
      obj_r_dup.should_receive(:close).and_return(nil)
      obj_r = mock("reader_io")
      obj_r.should_receive(:dup).and_return(obj_r_dup)
      obj_w = mock("writer_io")
      obj_w.should_receive(:dup).and_raise(IOError.new('closed stream'))
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)
      -> { io.dup }.should raise_error(IOError, 'closed stream')
    end

    it "raises IOError if the stream is closed" do
      obj_r = mock("reader_io")
      obj_w = mock("writer_io")
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)

      io.close
      -> { io.dup }.should raise_error(IOError, 'closed stream')
    end

    it "sets the autoclose flag on the new stream" do
      obj_r_dup = mock("reader_io_dup")
      obj_r_dup.should_receive(:close).and_return(nil).exactly(2)
      obj_r = mock("reader_io")
      obj_r.should_receive(:dup).and_return(obj_r_dup).exactly(2)
      obj_w_dup = mock("writer_io_dup")
      obj_w_dup.should_receive(:close).and_return(nil).exactly(2)
      obj_w = mock("writer_io")
      obj_w.should_receive(:dup).and_return(obj_w_dup).exactly(2)
      io = IO::LikeHelpers::DuplexedIO.new(obj_r, obj_w, autoclose: false)

      io.autoclose = true
      io_dup = io.dup
      io_dup.autoclose?.should be_true
      io_dup.close

      io.autoclose = false
      io_dup = io.dup
      io_dup.autoclose?.should be_true
      io_dup.close
    end
  end
end

# vim: ts=2 sw=2 et
