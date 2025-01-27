# frozen_string_literal: true
require 'io/like_helpers/character_io/basic_reader'

class IO; module LikeHelpers; class CharacterIO

##
# This class is a character reader that converts bytes from one character
# encoding to another.  It is also used when simply handling universal newline
# conversion.
# 
# @api private
class ConverterReader < BasicReader
  # This comes from MRI.
  MIN_BUFFER_SIZE = 128 * 1024

  ##
  # Creates a new intance of this class.
  #
  # @param buffered_io [LikeHelpers::BufferedIO] a readable stream that always
  #   blocks
  # @param buffer_size [Integer, nil] the size of the internal buffer
  # @param encoding_opts [Hash] 
  # @param external_encoding [Encoding, nil] the encoding to apply to the
  #   content provided by the underlying stream
  # @param internal_encoding [Encoding, nil] the encoding into which characters
  #   from the underlying stream are converted
  #
  # Note that `MIN_BUFFER_SIZE` is used for the buffer size when `buffer_size`
  # is `nil` or less than `MIN_BUFFER_SIZE`.
  #
  # When `internal_encoding` is `nil`, character conversion is not performed,
  # but newline conversion will still be performed if `encoding_opts` specifies
  # such.
  def initialize(
    buffered_io,
    buffer_size: MIN_BUFFER_SIZE,
    encoding_opts: {},
    external_encoding: nil,
    internal_encoding: nil
  )
    super(buffered_io, encoding: internal_encoding || external_encoding)

    if ! buffer_size || buffer_size < MIN_BUFFER_SIZE
      buffer_size = MIN_BUFFER_SIZE
    end
    @buffer_size = buffer_size
    @start_idx = @end_idx = @buffer_size
    @buffer = "\0".b * @buffer_size
    @converter = internal_encoding ?
      Encoding::Converter.new(
       external_encoding, internal_encoding, **encoding_opts
      ) :
      Encoding::Converter.new('', '', **encoding_opts)
  end

  ##
  # Clears the state of this reader.
  #
  # @return [nil]
  def clear
    super
    @start_idx = @end_idx = @buffer_size
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
  def content
    @buffer[@start_idx..@end_idx-1]
  end

  ##
  # Consumes bytes from the front of the buffer.
  #
  # @param length [Integer] the number of bytes to consume
  #
  # @return [nil]
  def consume(length)
    existing_content_size = @end_idx - @start_idx
    length = existing_content_size if length > existing_content_size
    @start_idx += length
    nil
  end

  ##
  # Returns `true` if the read buffer is empty and `false` otherwise.
  #
  # @return [Boolean]
  def empty?
    @start_idx >= @end_idx
  end

  ##
  # Refills the buffer from the stream.
  #
  # @param many [Boolean] read and convert only 1 character when `false`;
  #   otherwise, read and convert many characters
  #
  # @return [nil]
  #
  # @raise [Encoding::InvalidByteSequenceError] if character conversion is being
  #   performed and the next sequence of bytes are invalid in the external
  #   encoding
  # @raise [Encoding::UndefinedConversionError] if character conversion is being
  #   performed and the character read from the stream cannot be converted to a
  #   character in the target encoding
  # @raise [EOFError] when reading at the end of the stream
  # @raise [IOError] if the stream is not readable
  # @raise [IOError] if the buffer is already full
  def refill(many = true)
    existing_content_size = @end_idx - @start_idx
    # Nothing to do if the character buffer is already full.
    return nil if existing_content_size >= @buffer_size

    conversion_buffer = ''.b

    conversion_options = Encoding::Converter::PARTIAL_INPUT
    conversion_options |= Encoding::Converter::AFTER_OUTPUT unless many

    begin
      loop do
        buffered_io.refill if buffered_io.read_buffer_empty?
        input = buffered_io.peek
        input_count = input.bytesize

        result = @converter.primitive_convert(
          input,
          conversion_buffer,
          0,
          @buffer_size - existing_content_size,
          conversion_options
        )

        case result
        when :after_output, :source_buffer_empty, :destination_buffer_full
          consumed = input_count - input.bytesize
          buffered_io.skip(consumed)
          break unless conversion_buffer.empty?
          next
        when :invalid_byte_sequence
          putback = @converter.putback
          consumed = input_count - input.bytesize - putback.bytesize
          buffered_io.skip(consumed)
        end

        raise @converter.last_error
      end
    rescue EOFError
      conversion_buffer << @converter.finish
      # Ignore this if there is still buffered data.
      raise if conversion_buffer.empty?
    end

    append_to_buffer(conversion_buffer.b)

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
  def unread(buffer, length: buffer.bytesize)
    existing_content_size = @end_idx - @start_idx
    if length > @buffer_size - existing_content_size
      raise IOError, 'insufficient buffer space for unread'
    end

    prepend_to_buffer(buffer.b[0, length])

    nil
  end

  private

  ##
  # Appends `content` to the end of the internal buffer, shifting existing
  # content to the beginning of the buffer first.
  #
  # @param content [String] the bytes to insert into the buffer
  #
  # @return [nil]
  def append_to_buffer(content)
    shift_content_to_beginning
    @buffer[@end_idx, content.bytesize] = content.b
    @end_idx += content.bytesize
    nil
  end

  ##
  # Prepends `content` to the beginning of the internal buffer, shifting
  # existing content to the end of the buffer first.
  #
  # @param content [String] the bytes to insert into the buffer
  #
  # @return [nil]
  def prepend_to_buffer(content)
    shift_content_to_end
    @start_idx -= content.bytesize
    @buffer[@start_idx, content.bytesize] = content.b
    nil
  end

  ##
  # Shifts data in the buffer to the beginning if it is not already at the
  # beginning.
  #
  # @return [nil]
  def shift_content_to_beginning
    if @start_idx > 0
      existing_content_size = @end_idx - @start_idx
      if existing_content_size > 0
        @buffer[0, existing_content_size] = @buffer[@start_idx, existing_content_size]
      end
      @start_idx = 0
      @end_idx = existing_content_size
    end
    nil
  end

  ##
  # Shifts data in the buffer to the end if it is not already at the end.
  #
  # @return [nil]
  def shift_content_to_end
    if @end_idx < @buffer_size
      existing_content_size = @end_idx - @start_idx
      new_start_idx = @buffer_size - existing_content_size
      @buffer[new_start_idx, existing_content_size] =
        @buffer[@start_idx, existing_content_size]
      @start_idx = new_start_idx
      @end_idx = @buffer_size
    end
    nil
  end
end
end; end; end
