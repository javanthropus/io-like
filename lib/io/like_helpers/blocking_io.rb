# frozen_string_literal: true

require 'io/like_helpers/delegated_io'

class IO; module LikeHelpers

##
# This class implements a stream that always blocks regardless of the blocking
# state of the delegate.
class BlockingIO < DelegatedIO
  ##
  # Reads bytes from the stream.
  #
  # Note that a partial read will occur if the stream is in non-blocking mode
  # and reading more bytes would block.  If no bytes can be read, however, the
  # read will block until at least 1 byte can be read.
  #
  # @param length [Integer] the number of bytes to read
  # @param buffer [String] the buffer into which bytes will be read (encoding
  #   assumed to be binary)
  #
  # @return [Integer] the number of bytes read if `buffer` is not `nil`
  # @return [String] a buffer containing the bytes read if `buffer` is `nil`
  #
  # @raise [EOFError] when reading at the end of the stream
  # @raise [IOError] if the stream is not readable
  def read(length, buffer: nil)
    ensure_blocking { super }
  end

  ##
  # Writes bytes to the stream.
  #
  # Note that a partial write will occur if the stream is in non-blocking mode
  # and writing more bytes would block.  If no bytes can be written, however,
  # the write will block until at least 1 byte can be written.
  #
  # @param buffer [String] the bytes to write (encoding assumed to be binary)
  # @param length [Integer] the number of bytes to write from `buffer`
  #
  # @return [Integer] the number of bytes written
  #
  # @raise [IOError] if the stream is not writable
  def write(buffer, length: buffer.bytesize)
    ensure_blocking { super }
  end

  private

  ##
  # Runs the given block in a wait loop that exits only when the block returns a
  # non-Symbol value.
  #
  # This method is intended to wrap an IO operation that may be non-blocking and
  # effectively turn it into a blocking operation without changing underlying
  # settings of the stream itself.
  #
  # @return the return value of the block if not a Symbol
  #
  # @raise [RuntimeError] if the Symbol returned by the block is neither
  #   `:wait_readable` nor `:wait_writable`
  def ensure_blocking
    begin
      while Symbol === (result = yield) do
        # A wait timeout is used in order to allow a retry in case the stream was
        # closed in another thread while waiting.
        case result
        when :wait_readable
          wait(IO::READABLE, 1)
        when :wait_writable
          wait(IO::WRITABLE, 1)
        else
          raise "Unexpected result: #{result}"
        end
      end
    rescue Errno::EINTR
      retry
    end

    result
  end
end

end; end
