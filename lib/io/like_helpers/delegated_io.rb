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
             elsif RubyFacts::RBVER_LT_2_7
               '*args, &b'
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
  # Creates a new intance of this class.
  #
  # @param delegate [LikeHelpers::AbstractIO] a readable and/or writable stream
  # @param autoclose [Boolean] when `true` close the delegate when this stream
  #   is closed
  def initialize(delegate, autoclose: true)
    raise ArgumentError, 'delegate cannot be nil' if delegate.nil?
    super()

    @delegate = delegate
    @autoclose = autoclose
  end

  ##
  # Sets whether or not to close the delegate when {#close} is called.
  #
  # @param autoclose [Boolean] delegate will be closed when `true`
  def autoclose=(autoclose)
    assert_open
    @autoclose = autoclose ? true : false
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

    if @autoclose
      result = delegate.close
      return result if Symbol === result
    end
    super

    nil
  end

  ##
  # @return [String] a string representation of this object
  def inspect
    "<#{self.class}:#{delegate.inspect}>"
  end

  ##
  # Returns `true` if the stream is readable and `false` otherwise.
  #
  # @return [Boolean]
  def readable?
    return false if closed?
    delegate.readable?
  end


  ##
  # Returns `true` if the stream is writable and `false` otherwise.
  #
  # @return [Boolean]
  def writable?
    return false if closed?
    delegate.writable?
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
  # @method read(*args, **kwargs, &b)
  # Calls `delegate.read(*args, **kwargs, &b)` after asserting that the stream is readable.
  delegate :read, assert: :readable

  ##
  # @method write(*args, **kwargs, &b)
  # Calls `delegate.write(*args, **kwargs, &b)` after asserting that the stream is writable.
  delegate :write, assert: :writable

  private

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

    @autoclose = true
    @delegate = @delegate.dup

    nil
  end

  ##
  # The delegate that receives delegated method calls.
  attr_reader :delegate
end
end; end

# vim: ts=2 sw=2 et
