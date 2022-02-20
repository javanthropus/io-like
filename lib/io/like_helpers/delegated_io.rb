require 'io/like_helpers/abstract_io'
require 'io/like_helpers/ruby_facts.rb'

class IO; module LikeHelpers
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

  def initialize(delegate, autoclose: true)
    raise ArgumentError, 'delegate cannot be nil' if delegate.nil?
    super()

    @delegate = delegate
    @autoclose = autoclose
  end

  ##
  # Sets whether or not to close the delegate(s) when {#close} is called.
  #
  # @param autoclose [Boolean] delegate(s) will be closed when `true`
  def autoclose=(autoclose)
    assert_open
    @autoclose = autoclose ? true : false
    autoclose
  end

  ##
  # @return [true] if delegate(s) would be closed when {#close} is called
  # @return [false] if delegate(s) would **not** be closed when {#close} is called
  def autoclose?
    assert_open
    @autoclose
  end

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

  delegate :advise, :close_on_exec=, :close_on_exec?, :fcntl, :fdatasync, :fileno, :fsync, :ioctl, :nonblock=, :nonblock?, :path, :pid, :ready?, :seek, :stat, :to_io, :tty?, :wait

  delegate :read, assert: :readable

  def readable?
    return false if closed?
    delegate.readable?
  end

  delegate :write, assert: :writable

  def writable?
    return false if closed?
    delegate.writable?
  end

  private

  def initialize_copy(other)
    super

    @autoclose = true
    @delegate = @delegate.dup

    nil
  end

  attr_reader :delegate
end
end; end

# vim: ts=2 sw=2 et
