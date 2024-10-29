# frozen_string_literal: true

require 'io/like_helpers/blocking_io'
require 'io/like_helpers/buffered_io'
require 'io/like_helpers/character_io'
require 'io/like_helpers/delegated_io'

class IO; module LikeHelpers

##
# This class creates a pipeline of streams necessary to satisfy the internal
# needs of IO::Like:
#   CharacterIO >> BufferedIO >> BlockingIO >> delegate
#   
# Each segment of the pipeline is directly accessible so that the methods of
# IO::Like may use them as necessary.
class Pipeline < DelegatedIO
  ##
  # Creates a new intance of this class.
  #
  # @param delegate [LikeHelpers::AbstractIO] a readable and/or writable stream
  # @param autoclose [Boolean] when `true` close the delegate when this stream
  #   is closed
  def initialize(
    delegate,
    autoclose: true
  )
    raise ArgumentError, 'delegate cannot be nil' if delegate.nil?

    super(BufferedIO.new(BlockingIO.new(delegate, autoclose: autoclose)))

    @character_io = CharacterIO.new(buffered_io, blocking_io)
  end

  ##
  # A better name for the delegate of this stream that correctly identifies it
  # as a BufferedIO instance.
  alias_method :buffered_io, :delegate
  public :buffered_io

  ##
  # @return a reference to the BlockingIO delegate of the BufferedIO
  def blocking_io
    buffered_io.delegate
  end

  ##
  # A references to the CharacterIO instance
  attr_reader :character_io

  ##
  # @return a reference to the original delegate given to the initializer of
  #   this stream
  def concrete_io
    blocking_io.delegate
  end

  private

  ##
  # Creates an instance of this class that copies state from `other`.
  #
  # @param other [Pipeline] the instance to copy
  #
  # @return [nil]
  #
  # @raise [IOError] if `other` is closed
  def initialize_copy(other)
    super

    @character_io = @character_io.dup
    @character_io.buffered_io = buffered_io
    @character_io.blocking_io = blocking_io
  end
end

end; end
