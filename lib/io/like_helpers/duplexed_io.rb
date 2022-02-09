require 'io/like_helpers/delegated_io'

class IO; module LikeHelpers
class DuplexedIO < DelegatedIO
  def initialize(delegate_r, delegate_w = delegate_r, autoclose: true)
    raise ArgumentError, 'delegate_r cannot be nil' if delegate_r.nil?
    raise ArgumentError, 'delegate_w cannot be nil' if delegate_w.nil?

    super(delegate_r, autoclose: autoclose)

    @delegate_w = delegate_w
    @closed_write = false
  end

  def initialize_dup(other)
    super

    @delegate_w = other.duplexed? ? @delegate_w.dup : @delegate
  end

  def close
    return nil if closed?

    result = close_write
    return result if Symbol === result
    result = close_read
    return result if Symbol === result

    nil
  end

  alias_method :closed_read?, :closed?
  def closed?
    closed_read? && closed_write?
  end

  def closed_write?
    @closed_write
  end

  def close_read
    return nil if closed_read?

    if @autoclose
      result = delegate_r.close
      return result if Symbol === result
    end
    @closed_write = true unless duplexed?
    @closed = true
    @delegate = @delegate_w

    nil
  end

  def close_write
    return nil if closed_write?

    if @autoclose
      result = delegate_w.close
      return result if Symbol === result
    end
    @closed = true unless duplexed?
    @closed_write = true
    @delegate_w = @delegate

    nil
  end

  def close_on_exec=(close_on_exec)
    return super unless duplexed?

    assert_open

    delegate_r.close_on_exec = delegate_w.close_on_exec = close_on_exec

    close_on_exec
  end

  ##
  # @return [String] a string representation of this object
  def inspect
    return super unless duplexed?
    "<#{self.class}:#{delegate_r.inspect}, #{delegate_w.inspect}>"
  end

  def nonblock=(nonblock)
    return super unless duplexed?

    assert_open

    delegate_r.nonblock = delegate_w.nonblock = nonblock

    nonblock
  end

  def readable?
    return false if closed_read?
    delegate_r.readable?
  end

  delegate :write, to: :delegate_w, assert: :writable

  def writable?
    return false if closed_write?
    delegate_w.writable?
  end

  protected

  def duplexed?
    delegate_r != delegate_w
  end

  private

  attr_reader :delegate_w
  alias_method :delegate_r, :delegate
end
end; end

# vim: ts=2 sw=2 et
