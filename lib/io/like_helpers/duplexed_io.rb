# frozen_string_literal: true

require 'io/like_helpers/delegated_io'

class IO; module LikeHelpers

##
# This class encapsulates 2 streams (one readable, one writable) into a single
# stream.  It is primarily intended to serve as an ancestor for {IO::Like} and
# should not be used directly.
class DuplexedIO < DelegatedIO
  ##
  # Creates a new intance of this class.
  #
  # @param delegate_r [LikeHelpers::AbstractIO] a readable stream
  # @param delegate_w [LikeHelpers::AbstractIO] a writable stream
  # @param autoclose [Boolean] when `true` close the delegate when this stream
  #   is closed
  def initialize(delegate_r, delegate_w = delegate_r, autoclose: true)
    raise ArgumentError, 'delegate_r cannot be nil' if delegate_r.nil?
    raise ArgumentError, 'delegate_w cannot be nil' if delegate_w.nil?

    @delegate_w = delegate_w
    @closed_write = false

    super(delegate_r, autoclose: autoclose)
  end

  ##
  # Closes this stream.
  #
  # The delegates are closed if autoclose is enabled for the stream.
  #
  # @return [nil] on success
  # @return [:wait_readable, :wait_writable] if the stream is non-blocking and
  #   the operation would block
  def close
    return nil if closed?

    begin
      result = close_write
    ensure
      # Complete the closing process if the writable delegate closed normally or
      # an exception was raised.
      result = close_read unless Symbol === result
    end

    result
  end

  ##
  # Returns `true` if the readable delegate is closed and `false` otherwise.
  #
  # @return [Boolean]
  alias_method :closed_read?, :closed?

  ##
  # Returns `true` if both delegates are closed and `false` otherwise.
  #
  # @return [Boolean]
  def closed?
    closed_read? && closed_write?
  end

  ##
  # Returns `true` if the writable delegate is closed and `false` otherwise.
  #
  # @return [Boolean]
  def closed_write?
    @closed_write
  end

  ##
  # Closes the readable delegate.
  #
  # @return [nil] on success
  # @return [:wait_readable, :wait_writable] if the stream is non-blocking and
  #   the operation would block
  def close_read
    return nil if closed_read?

    begin
      result = delegate_r.close if @autoclose
    ensure
      # Complete the closing process if the delegate closed normally or an
      # exception was raised.
      unless Symbol === result
        @closed_write = true unless duplexed?
        @closed = true
        @delegate = @delegate_w
        disable_finalizer
        enable_finalizer if @autoclose && ! closed?
      end
    end

    result
  end

  ##
  # Closes the writable delegate.
  #
  # @return [nil] on success
  # @return [:wait_readable, :wait_writable] if the stream is non-blocking and
  #   the operation would block
  def close_write
    return nil if closed_write?

    begin
      result = delegate_w.close if @autoclose
    ensure
      # Complete the closing process if the delegate closed normally or an
      # exception was raised.
      unless Symbol === result
        @closed = true unless duplexed?
        @closed_write = true
        @delegate_w = @delegate
        disable_finalizer
        enable_finalizer if @autoclose && ! closed?
      end
    end

    result
  end

  ##
  # Sets the close-on-exec flag for the underlying file descriptors of the
  # delegates.
  #
  # Note that setting this to `false` can lead to file descriptor leaks in
  # multithreaded applications that fork and exec or use the `system` method.
  #
  # @return [Boolean]
  def close_on_exec=(close_on_exec)
    return super unless duplexed?

    assert_open

    delegate_w.close_on_exec = delegate_r.close_on_exec = close_on_exec

    close_on_exec
  end

  ##
  # @return [String] a string representation of this object
  def inspect
    return super unless duplexed?
    "<#{self.class}:#{delegate_r.inspect}, #{delegate_w.inspect}>"
  end

  ##
  # Sets the blocking mode for the stream.
  #
  # @return [Boolean]
  def nonblock=(nonblock)
    return super unless duplexed?

    assert_open

    delegate_w.nonblock = delegate_r.nonblock = nonblock

    nonblock
  end

  ##
  # @method pwrite(*args, **kwargs, &b)
  # Calls `delegate_w.write(*args, **kwargs, &b)` after asserting that the stream is writable.
  delegate :pwrite, to: :delegate_w, assert: :writable

  ##
  # Returns `true` if the stream is readable and `false` otherwise.
  #
  # @return [Boolean]
  def readable?
    return false if closed_read?
    return @readable if defined?(@readable) && ! @readable.nil?
    @readable = delegate_r.readable?
  end

  ##
  # @method write(*args, **kwargs, &b)
  # Calls `delegate_w.write(*args, **kwargs, &b)` after asserting that the stream is writable.
  delegate :write, to: :delegate_w, assert: :writable

  ##
  # Returns `true` if the stream is writable and `false` otherwise.
  #
  # @return [Boolean]
  def writable?
    return false if closed_write?
    return @writable if defined?(@writable) && ! @writable.nil?
    @writable = delegate_w.writable?
  end

  protected

  ##
  # Returns `true` if the stream is duplexed and `false` otherwise.
  #
  # Note that a duplexed stream can become non-duplexed if one of the delegates
  # is closed via {#close_read} or {#close_write}.
  #
  # @return [Boolean]
  def duplexed?
    delegate_r != delegate_w
  end

  private

  ##
  # Defines a finalizer for this object.
  #
  # @return [nil]
  def enable_finalizer
    if duplexed?
      ObjectSpace.define_finalizer(
        self, self.class.create_finalizer(delegate_w)
      )
    end
    super
  end

  ##
  # Creates an instance of this class that copies state from `other`.
  #
  # The delegates of `other` are `dup`'d.
  #
  # @param other [DuplexedIO] the instance to copy
  #
  # @return [nil]
  #
  # @raise [IOError] if `other` is closed
  def initialize_copy(other)
    super

    disable_finalizer
    begin
      @delegate_w = other.duplexed? ? @delegate_w.dup : @delegate
      self.autoclose = true
    rescue
      delegate_r.close rescue nil
      raise
    end

    nil
  end

  ##
  # The writable delegate.
  attr_reader :delegate_w

  ##
  # @!attribute [r] delegate_r
  #   @overload delegate_r
  #     The readable delegate.
  alias_method :delegate_r, :delegate
end
end; end

# vim: ts=2 sw=2 et
