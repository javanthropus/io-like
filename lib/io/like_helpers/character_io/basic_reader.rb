# frozen_string_literal: true

class IO; module LikeHelpers; class CharacterIO

##
# This class exists mostly to provide an interface that is compatible with that
# of ConverterReader.  It is otherwise a thin wrapper around the BufferedIO
# instance provided to it as a data source.
# 
# @api private
class BasicReader
  ##
  # Creates a new intance of this class.
  #
  # @param buffered_io [LikeHelpers::BufferedIO] a readable stream that always
  #   blocks
  # @param encoding [Encoding, nil] the encoding to apply to the content provided by
  #   this stream
  #
  # When `encoding` is `nil`, #encoding will return the current value of
  # Encoding.default_external when called.
  def initialize(
    buffered_io,
    encoding: nil
  )
    @buffered_io = buffered_io
    @encoding = encoding ? Encoding.find(encoding) : nil
  end

  ##
  # Clears the state of this reader.
  #
  # @return [nil]
  def clear
    buffered_io.flush
    nil
  end

  ##
  # Returns the bytes of the buffer as a binary encoded String.
  #
  # The returned bytes should be encoded using the value of {#encoding} and
  # `String#force_encoding`.  Bytes are returned rather than characters because
  # CharacterIO#read_line works on bytes for compatibility with the MRI
  # implementation and working with characters would be inefficient in that
  # case.
  #
  # @return [String] the bytes of the buffer
  #
  # @raise [IOError] if the stream is not readable
  def content
    buffered_io.peek
  end

  ##
  # Consumes bytes from the front of the buffer.
  #
  # @param length [Integer, nil] the number of bytes to consume
  #
  # @return [nil]
  #
  # @raise [IOError] if the stream is not readable
  def consume(length)
    buffered_io.skip(length)
    nil
  end

  ##
  # Returns `true` if the read buffer is empty and `false` otherwise.
  # 
  # This implementation does not have its own a buffer, so this method always
  # returns `true`.
  #
  # @return [Boolean]
  def empty?
    true
  end

  ##
  # @return [Encoding] the encoding to apply on byte strings from #content
  def encoding
    @encoding || Encoding.default_external
  end

  ##
  # Refills the buffer from the stream.
  #
  # @param many [Boolean] ignored in this implementation; see
  #   ConverterReader#refill
  #
  # @return [nil]
  #
  # @raise [EOFError] when reading at the end of the stream
  # @raise [IOError] if the stream is not readable
  # @raise [IOError] if the buffer is already full
  def refill(many = true)
    bytes_added = buffered_io.refill
    raise IOError, 'no bytes read' if bytes_added < 1
    nil
  end

  ##
  # Places bytes at the beginning of the read buffer.
  #
  # @param buffer [String] the bytes to insert into the read buffer
  # @param length [Integer] the number of bytes from the beginning of `buffer`
  #   to insert into the read buffer
  #
  # @return [nil]
  #
  # @raise [IOError] if the remaining space in the internal buffer is
  #   insufficient to contain the given data
  # @raise [IOError] if the stream is not readable
  def unread(buffer, length: buffer.bytesize)
    return buffered_io.unread(buffer, length: length)
  end

  private

  attr_reader :buffered_io
end
end; end; end
