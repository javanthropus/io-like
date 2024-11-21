# frozen_string_literal: true
require 'io/like_helpers/character_io/basic_reader'
require 'io/like_helpers/character_io/converter_reader'
require 'io/like_helpers/ruby_facts'

class IO; module LikeHelpers

##
# This class implements a stream that reads or writes characters to or from a
# byte oriented stream.
class CharacterIO
  include RubyFacts

  ##
  # Creates a new intance of this class.
  #
  # @param buffered_io [LikeHelpers::BufferedIO] a readable and/or writable
  #   stream that always blocks
  # @param blocking_io [LikeHelpers::BlockingIO] a readable and/or writable
  #   stream that always blocks
  # @param internal_encoding [Encoding, String] the internal encoding
  # @param external_encoding [Encoding, String] the external encoding
  # @param encoding_opts [Hash] options to be passed to String#encode
  # @param sync [Boolean] when `true` causes write operations to bypass internal
  #   buffering
  def initialize(
    buffered_io,
    blocking_io = buffered_io,
    encoding_opts: {},
    external_encoding: nil,
    internal_encoding: nil,
    sync: false
  )
    raise ArgumentError, 'buffered_io cannot be nil' if buffered_io.nil?
    raise ArgumentError, 'blocking_io cannot be nil' if blocking_io.nil?

    @buffered_io = buffered_io
    @blocking_io = blocking_io
    self.sync = sync

    set_encoding(external_encoding, internal_encoding, **encoding_opts)
  end

  attr_accessor :buffered_io
  attr_accessor :blocking_io

  ##
  # Returns `true` if the read buffer is empty and `false` otherwise.
  #
  # @return [Boolean]
  def buffer_empty?
    return true unless readable?
    character_reader.empty?
  end

  ##
  # The external encoding of this stream.
  attr_reader :external_encoding

  ##
  # The internal encoding of this stream.  This is only used for read
  # operations.
  attr_reader :internal_encoding

  ##
  # Reads all remaining characters from the stream.
  #
  # @return [String] a buffer containing the characters that were read
  #
  # @raise [Encoding::InvalidByteSequenceError] if character conversion is being
  #   performed and the next sequence of bytes are invalid in the external
  #   encoding
  # @raise [EOFError] when reading at the end of the stream
  # @raise [IOError] if the stream is not readable
  def read_all
    # TODO:
    # Remove this method and merge its tests with the read_line tests.
    return read_line(separator: nil)
  end

  ##
  # Returns the next character from the stream.
  #
  # @return [String] a buffer containing the character that was read
  #
  # @raise [EOFError] when reading at the end of the stream
  # @raise [IOError] if the stream is not readable
  def read_char
    char = nil

    begin
      # The delegate's read buffer will have at least 1 byte in it at this
      # point.
      loop do
        buffer = character_reader.content
        char = buffer.force_encoding(character_reader.encoding)[0]
        # Return the next character if it is valid for the encoding.
        break if ! char.nil? && char.valid_encoding?
        # Or if the buffer has more than 16 bytes in it, valid or not.
        break if buffer.bytesize >= 16

        character_reader.refill(false)
        # At least 1 byte was added to the buffer, so try again.
      end
    rescue EOFError, IOError
      # Reraise when no bytes were available.
      raise if char.nil?
    end

    character_reader.consume(char.bytesize)
    char
  end

  ##
  # Returns the next line from the stream.
  #
  # @param separator [String, nil] a non-empty String that separates each
  #   line, an empty String that equates to 2 or more successive newlines as
  #   the separator, or `nil` to indicate reading all remaining data
  # @param limit [Integer, nil] an Integer limiting the number of bytes
  #   returned in each line or `nil` to indicate no limit
  # @param chomp [Boolean] when `true` trailing newlines and carriage returns
  #   will be removed from each line
  #
  # @return [String] a buffer containing the characters that were read
  #
  # @raise [EOFError] when reading at the end of the stream
  # @raise [IOError] if the stream is not readable
  def read_line(separator: $/, limit: nil, chomp: false, discard_newlines: false)
    if String === separator && separator.encoding != Encoding::BINARY
      separator = separator.encode(character_reader.encoding).b
    end
    content = String.new(encoding: Encoding::BINARY)

    return content.force_encoding(character_reader.encoding) if limit == 0

    begin
      self.discard_newlines if discard_newlines

      index = nil
      extra = 0
      need_more = false
      offset = 0
      loop do
        already_consumed = content.bytesize
        content << character_reader.content

        if separator && ! index
          if Regexp === separator
            match = content.match(separator, offset)
            if match
              index = match.end(0)
              # Truncate the content to the end of the separator.
              content.slice!(index..-1)
            end
          else
            index = content.index(separator, offset)
            if index
              index += separator.bytesize
              # Truncate the content to the end of the separator.
              content.slice!(index..-1)
            else
              # Optimize the search that happens in the next loop iteration by
              # excluding the range of bytes already searched.
              offset = [0, content.bytesize - separator.bytesize + 1].max
            end
          end
        end

        if limit && limit < content.bytesize
          # Truncate the content to no more than limit + 16 bytes in order to
          # ensure that the last character is not truncated at the limit
          # boundary.
          need_more =
            loop do
              last_character =
                content[0, limit + extra]
                .force_encoding(character_reader.encoding)[-1]
              # No more bytes are needed because the last character is whole and
              # valid or we hit the limit + 16 bytes hard limit.
              break false if last_character.valid_encoding?
              break false if extra >= 16
              extra += 1
              # More bytes are needed, but the end of the character buffer has
              # been reached.
              break true if limit + extra > content.bytesize
            end

          content.slice!((limit + extra)..-1) unless need_more
        end

        character_reader.consume(content.bytesize - already_consumed)

        # The separator string was found.
        break if index
        # The limit was reached.
        break if limit && content.bytesize >= limit && ! need_more

        character_reader.refill
      end

      self.discard_newlines if discard_newlines
    rescue EOFError
      raise if content.empty?
    end

    if chomp
      if separator
        # When the separator is provided, remove the separator.
        content.slice!(separator)
      elsif RBVER_LT_3_2 && ! separator && ! limit
        # A default chomp is performed on Ruby <3.2 in the read all case even
        # though the separator is not provided there.
        content.chomp!
      end
    end

    content.force_encoding(character_reader.encoding)
  end

  ##
  # Returns `true` if the stream is readable and `false` otherwise.
  #
  # @return [Boolean]
  def readable?
    return @readable if defined?(@readable) && ! @readable.nil?
    @readable = buffered_io.readable?
  end

  ##
  # Clears the state of this stream.
  #
  # @return [nil]
  def clear
    return unless @character_reader
    @character_reader.clear
    nil
  end

  ##
  # Sets the external and internal encodings of the stream.
  #
  # @param external [Encoding, nil] the external encoding
  # @param internal [Encoding, nil] the internal encoding
  # @param opts [Hash] encoding conversion options used when character or
  #   newline conversion is performed
  #
  # @return [nil]
  def set_encoding(external, internal, **opts)
    if external.nil? && ! internal.nil?
      raise ArgumentError,
        'External encoding cannot be nil when internal encoding is not nil'
    end

    internal = nil if internal == external

    self.encoding_opts = opts
    @internal_encoding = internal
    @external_encoding = external
    @character_reader = nil

    nil
  end

  ##
  # When set to `true` the internal write buffer will be bypassed.  Any data
  # currently in the buffer will be flushed prior to the next output operation.
  # When set to `false`, the internal write buffer will be enabled.
  #
  # @param sync [Boolean] the sync mode
  #
  # @return [Boolean] the given value for `sync`
  def sync=(sync)
    @sync = sync ? true : false
  end

  ##
  # @return [Boolean] `true` if the internal write buffer is being bypassed and
  #   `false` otherwise
  def sync?
    @sync ||= false
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
    length = Integer(length)
    raise ArgumentError, 'length must be at least 0' if length < 0

    assert_readable

    character_reader(length).unread(buffer.b, length: length)
  end

  ##
  # Returns `true` if the stream is writable and `false` otherwise.
  #
  # @return [Boolean]
  def writable?
    return @writable if defined?(@writable) && ! @writable.nil?
    @writable = buffered_io.writable?
  end

  ##
  # Writes characters to the stream, performing character and newline conversion
  # first if necessary.
  #
  # This method always blocks until all data is written.
  #
  # @param buffer [String] the characters to write
  #
  # @return [Integer] the number of bytes written, after conversion
  #
  # @raise [IOError] if the stream is not writable
  def write(buffer)
    assert_writable

    target_encoding = external_encoding
    if target_encoding.nil? || target_encoding == Encoding::BINARY
      target_encoding = buffer.encoding
    end
    if target_encoding != buffer.encoding || ! encoding_opts_w.empty?
      buffer = buffer.encode(target_encoding, **encoding_opts_w)
    end

    writer = sync? ? blocking_io : buffered_io
    buffer = buffer.b
    bytes_written = 0
    while bytes_written < buffer.bytesize do
      bytes_written += writer.write(buffer[bytes_written..-1])
    end
    bytes_written
  end

  private

  ##
  # Raises an exception if the stream is not open for reading.
  #
  # @return [nil]
  #
  # @raise IOError if the stream is not open for reading
  def assert_readable
    raise IOError, 'not opened for reading' unless readable?
  end

  ##
  # Raises an exception if the stream is not open for writing.
  #
  # @return [nil]
  #
  # @raise IOError if the stream is not open for writing
  def assert_writable
    raise IOError, 'not opened for writing' unless writable?
  end

  ##
  # @param buffer_size [Integer, nil] the size of the internal character buffer;
  #   ignored unless character or newline conversion will be performed
  #
  # @return [BasicReader, ConverterReader] a character reader based on the
  #   external encoding, internal encoding, and universal newline settings of
  #   this stream
  def character_reader(buffer_size = nil)
    return @character_reader if @character_reader

    # Hack the internal encoding to be the default internal encoding when:
    # 1. Ruby is less than version 3.3 (for compatibility)
    # 2. The internal encoding is not set explicitly
    # 3. Character conversion would be necessary with it set
    internal_encoding = self.internal_encoding
    if RBVER_LT_3_3 &&
       ! internal_encoding &&
       external_encoding != Encoding::BINARY &&
       external_encoding != Encoding.default_internal
      internal_encoding = Encoding.default_internal
    end

    @character_reader = if external_encoding &&
                           (internal_encoding || universal_newline?)
                          ConverterReader.new(
                            buffered_io,
                            buffer_size: buffer_size,
                            encoding_opts: encoding_opts_r,
                            external_encoding: external_encoding,
                            internal_encoding: internal_encoding
                          )
                        else
                          BasicReader.new(
                            buffered_io,
                            encoding: external_encoding
                          )
                        end
  end

  ##
  # Consumes 1 or more consecutive newline characters from the beginning of the
  # stream.
  #
  # @return [nil]
  def discard_newlines
    newline = String.new("\n")
    if RBVER_LT_3_4
      newline.encode!(internal_encoding) if internal_encoding
    else
      newline.encode!(character_reader.encoding)
    end
    newline.force_encoding(Encoding::BINARY)
    begin
      loop do
        # Consume bytes matching the newline character from the beginning of the
        # buffer.
        while character_reader.content.start_with?(newline) do
          character_reader.consume(newline.bytesize)
        end

        # Stop when adding more bytes to the buffer could not possibly complete
        # the newline character.
        break unless newline.start_with?(character_reader.content)

        # This will stop the loop by raising EOFError if there are no more
        # bytes.
        character_reader.refill
      end
    rescue EOFError
      # Stop when there are no more bytes to read from the stream.
    end

    nil
  end

  ##
  # Creates an instance of this class that copies state from `other`.
  #
  # @param other [CharacterIO] the instance to copy
  #
  # @return [nil]
  #
  # @raise [IOError] if `other` is closed
  def initialize_copy(other)
    super

    @character_reader = nil

    nil
  end

  ##
  # Sets the encoding options.
  #
  # @return _opts_
  def encoding_opts=(opts)
    if opts.key?(:newline) &&
       ! %i{universal crlf cr lf}.include?(opts[:newline])
      raise ArgumentError, "unexpected value for newline option: #{opts[:newline]}"
    end

    # Ruby ignores xml conversion as well as newline decorators other than
    # universal for reading.
    @encoding_opts_r = opts.reject do |k, v|
      k == :xml ||
      k == :crlf_newline || k == :cr_newline || k == :lf_newline ||
      (k == :newline && (v == :crlf || v == :cr || v == :lf))
    end

    # Ruby ignores the universal newline decorator for writing.
    @encoding_opts_w = opts.reject do |k, v|
      k == :universal_newline || (k == :newline && v == :universal)
    end

    opts
  end

  def universal_newline?
    encoding_opts_r[:newline] ?
      encoding_opts_r[:newline] == :universal :
      !!encoding_opts_r.fetch(:universal_newline, false)
  end

  ##
  # The encoding options for reading.
  attr_reader :encoding_opts_r

  ##
  # The encoding options for writing.
  attr_reader :encoding_opts_w
end
end; end

# vim: ts=2 sw=2 et
