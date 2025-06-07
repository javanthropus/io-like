# frozen_string_literal: true

require 'io/like_helpers/abstract_io'
require 'io/like_helpers/ruby_facts.rb'

class IO; module LikeHelpers

##
# This class implements {AbstractIO} by delegating most methods to a delegate
# stream.  Use this class to implement streams that filter or mutate data sent
# through them.
class DelegatedIO < AbstractIO
  ##
  # Defines methods for instances of this class that delegate calls to another
  # object.
  #
  # The delegation first calls an assert method to ensure the stream is in the
  # nessary state to be able to perform the delegation.
  #
  # @param methods [Array<Symbol>] a list of methods to delegate
  # @param to [Symbol] the target object
  # @param assert [Symbol] the kind of assertion to call (`:open`, `:readable`,
  #   or `:writable`)
  #
  # @return [Array<Symbol>] the names of the defined methods
  private_class_method def self.delegate(*methods, to: :delegate, assert: :open)
    unless %i{open readable writable}.include?(assert)
      raise ArgumentError, "Invalid assert: #{assert}"
    end

    location = caller_locations(1, 1).first
    file, line = location.path, location.lineno

    methods.map do |method|
      args = if /[^\]]=$/.match?(method)
               'arg'
             else
               '*args, **kwargs, &b'
             end

      method_def = <<-EOM
        def #{method}(#{args})
          assert_#{assert}
          #{to}.#{method}(#{args})
        end
      EOM
      module_eval(method_def, file, line)
    end
  end

  ##
  # @param delegate [LikeHelpers::AbstractIO] a readable and/or writable stream
  #
  # @return [Proc] a proc to be used as a fializer that calls #close on
  #   `delegate` when an instance of this class it garbage collected
  def self.create_finalizer(delegate)
    proc { |id| delegate.close }
  end

  ##
  # Creates a new intance of this class.
  #
  # @param delegate [LikeHelpers::AbstractIO] a readable and/or writable stream
  # @param autoclose [Boolean] when `true` close the delegate when this stream
  #   is closed
  def initialize(delegate, autoclose: true)
    raise ArgumentError, 'delegate cannot be nil' if delegate.nil?
    super()

    @delegate = delegate
    self.autoclose = autoclose
  end

  ##
  # Sets whether or not to close the delegate when {#close} is called.
  #
  # @param autoclose [Boolean] delegate will be closed when `true`
  def autoclose=(autoclose)
    assert_open
    @autoclose = autoclose ? true : false
    @autoclose ? enable_finalizer : disable_finalizer
    autoclose
  end

  ##
  # Returns `true` if the delegate would be closed when {#close} is called
  # and `false` otherwise.
  #
  # @return [Boolean]
  def autoclose?
    assert_open
    @autoclose
  end

  ##
  # Closes this stream.
  #
  # The delegate is closed if autoclose is enabled for the stream.
  #
  # @return [nil] on success
  # @return [:wait_readable, :wait_writable] if the stream is non-blocking and
  #   the operation would block
  def close
    return nil if closed?

    begin
      result = delegate.close if @autoclose
    ensure
      # Complete the closing process if the delegate closed normally or an
      # exception was raised.
      unless Symbol === result
        disable_finalizer
        result = super
      end
    end

    result
  end

  ##
  # @return [String] a string representation of this object
  def inspect
    "<#{self.class}:#{delegate.inspect}#{' (closed)' if closed?}>"
  end

  ##
  # Returns `true` if the stream is readable and `false` otherwise.
  #
  # @return [Boolean]
  def readable?
    return false if closed?
    return @readable if defined?(@readable) && ! @readable.nil?
    @readable = delegate.readable?
  end

  ##
  # Returns `true` if the stream is writable and `false` otherwise.
  #
  # @return [Boolean]
  def writable?
    return false if closed?
    return @writable if defined?(@writable) && ! @writable.nil?
    @writable = delegate.writable?
  end

  ##
  # @method close_on_exec=(value)
  # Calls `delegate.close_on_exec = value` after asserting that the stream is
  # open.
  delegate :close_on_exec=

  ##
  # @method nonblock=(value)
  # Calls `delegate.nonblock = value` after asserting that the stream is open.
  delegate :nonblock=

  # @!macro [attach] delegate_open
  #   @method $1(*args, **kwargs, &b)
  #   Calls `delegate.$1(*args, **kwargs, &b)` after asserting that the stream is open.
  delegate :advise
  delegate :close_on_exec?
  delegate :fcntl
  delegate :fdatasync
  delegate :fileno
  delegate :fsync
  delegate :ioctl
  delegate :nonblock?
  delegate :path
  delegate :pid
  delegate :ready?
  delegate :seek
  delegate :stat
  delegate :to_io
  delegate :tty?
  delegate :wait

  ##
  # @method pread(*args, **kwargs, &b)
  # Calls `delegate.read(*args, **kwargs, &b)` after asserting that the stream is readable.
  delegate :pread, assert: :readable

  ##
  # @method read(*args, **kwargs, &b)
  # Calls `delegate.read(*args, **kwargs, &b)` after asserting that the stream is readable.
  delegate :read, assert: :readable

  ##
  # @method nread(*args, **kwargs, &b)
  # Calls `delegate.nread(*args, **kwargs, &b)` after asserting that the stream is readable.
  delegate :nread, assert: :readable

  ##
  # @method pwrite(*args, **kwargs, &b)
  # Calls `delegate.write(*args, **kwargs, &b)` after asserting that the stream is writable.
  delegate :pwrite, assert: :writable

  ##
  # @method write(*args, **kwargs, &b)
  # Calls `delegate.write(*args, **kwargs, &b)` after asserting that the stream is writable.
  delegate :write, assert: :writable

  protected

  ##
  # The delegate that receives delegated method calls.
  attr_reader :delegate

  private

  ##
  # Removes all finalizers for this object.
  #
  # @return [nil]
  def disable_finalizer
    ObjectSpace.undefine_finalizer(self)
    nil
  end

  ##
  # Defines a finalizer for this object.
  #
  # @return [nil]
  def enable_finalizer
    ObjectSpace.define_finalizer(self, self.class.create_finalizer(delegate))
    nil
  end

  ##
  # Creates an instance of this class that copies state from `other`.
  #
  # The delegate of `other` is `dup`'d.
  #
  # @param other [DelegatedIO] the instance to copy
  #
  # @return [nil]
  #
  # @raise [IOError] if `other` is closed
  def initialize_copy(other)
    super

    disable_finalizer
    @delegate = @delegate.dup
    self.autoclose = true

    nil
  end
end
end; end

# vim: ts=2 sw=2 et
