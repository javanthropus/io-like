require 'io/like_helpers/delegated_io'

class IO; module LikeHelpers
class DuplexedIO < DelegatedIO
  def initialize(delegate_r, delegate_w = delegate_r, autoclose: true)
    raise ArgumentError, 'delegate_r cannot be nil' if delegate_r.nil?
    raise ArgumentError, 'delegate_w cannot be nil' if delegate_w.nil?

    super(delegate_r, autoclose: autoclose)

    @delegate_w = delegate_w

    @closed_read = false
    @closed_write = false
  end

  def initialize_dup(other)
    super

    @delegate_w = @delegate_w.dup
  end

  def delegate
    delegate_r.closed? ? delegate_w : delegate_r
  end

  def delegate_r
    @delegate
  end

  attr_reader :delegate_w

  def duplexed?
    delegate_r != delegate_w
  end

  def close
    return if closed?

    if @autoclose
      result = close_write
      return result if Symbol === result
      result = close_read
      return result if Symbol === result
    end

    nil
  end

  def closed?
    @closed_read && @closed_write
  end

  def closed_read?
    @closed_read
  end

  def closed_write?
    @closed_write
  end

  def close_read
    return if @closed_read

    delegate_r.close if autoclose?
    @closed_read = true
    @closed_write = true unless duplexed?

    nil
  end

  def close_write
    return if @closed_write

    delegate_w.close if autoclose?
    @closed_write = true
    @closed_read = true unless duplexed?

    nil
  end

  def close_on_exec=(close_on_exec)
    delegate_r.close_on_exec = delegate_w.close_on_exec = close_on_exec
    nil
  end

  def nonblock=(nonblock)
    delegate_r.nonblock = delegate_w.nonblock = nonblock
    nonblock
  end

  def read(length, buffer: nil)
    delegate_r.read(length, buffer: buffer)
  end

  def readable?
    delegate_r.readable?
  end

  def write(buffer, length: buffer.bytesize)
    delegate_w.write(buffer, length: length)
  end

  def writable?
    delegate_w.writable?
  end
end
end; end

# vim: ts=2 sw=2 et
