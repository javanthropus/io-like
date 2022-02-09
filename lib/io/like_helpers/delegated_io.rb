require 'io/like_helpers/abstract_io'
require 'io/like_helpers/ruby_facts.rb'

class IO; module LikeHelpers
class DelegatedIO < AbstractIO
  class << self
    def delegate(*methods, to: :delegate, assert: :open)
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
  end

  def initialize(delegate, autoclose: true)
    raise ArgumentError, 'delegate cannot be nil' if delegate.nil?
    super()

    @delegate = delegate
    @autoclose = autoclose
  end

  def initialize_dup(other)
    super

    @autoclose = true
    @delegate = @delegate.dup
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

  def closed?
    @closed
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

  attr_reader :delegate
end
end; end

# vim: ts=2 sw=2 et
