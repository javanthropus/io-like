require 'io/like'

class LikeStringIO
  include IO::Like

  def self.open(string = '', mode = 'rw')
    lsio = new(string, mode)
    return lsio unless block_given?

    begin
      yield(lsio)
    ensure
      lsio.close unless lsio.closed?
    end
  end

  def initialize(string = '', mode = 'rw')
    @unbuffered_pos = 0
    @string = string
    self.fill_size = 0
    self.flush_size = 0
    self.sync = true
    # TODO: These need to be set based on mode.
    @closed_read = false
    @closed_write = false
  end

  def close
    raise IOError, 'closed stream' if closed_read? && closed_write?
    close_read unless closed_read?
    close_write unless closed_write?
  end

  def close_read
    raise IOError, 'closing non-duplex IO for reading' if @closed_read
    @closed_read = true
  end

  def close_write
    raise IOError, 'closing non-duplex IO for writing' if @closed_write
    flush
    @closed_write = true
  end

  def closed?
    closed_read? && closed_write?
  end

  def closed_read?
    @closed_read
  end

  def closed_write?
    @closed_write
  end

  def eof
    @unbuffered_pos >= @string.length
  end
  alias :eof? :eof

  def readable?
    ! closed_read? && true
  end

  def size
    string.size
  end

  def string
    flush
    @string
  end

  def string=(string)
    @string = string
    @unbuffered_pos = 0
    internal_read_buffer.slice!(0..-1)
    internal_write_buffer.slice!(0..-1)
  end

  def truncate(length)
    raise IOError, 'not opened for writing' unless writable?
    raise Errno::EINVAL, 'Invalid argument - negative length' unless length > 0

    if length > @string.length then
      @string += "\000" * (length - @string.length)
    else
      @string.slice!(0, length)
    end

    length
  end

  def unread(string)
    raise IOError, 'closed stream' if closed_read?
    raise IOError, 'not opened for reading' unless readable?

    # Pad any space between the end of the wrapped string and the current
    # position with null characters.
    if @unbuffered_pos > @string.length then
      @string << ("\000" * (@unbuffered_pos - @string.length))
    end

    length = [string.length, @unbuffered_pos].min
    old_pos = @unbuffered_pos
    @unbuffered_pos -= length
    @string = @string.slice(0, @unbuffered_pos) +
              string.slice(-length, length) +
              @string.slice(old_pos..-1)

    nil
  end

  def writable?
    ! closed_write? && true
  end

  private

  def unbuffered_read(length)
    # Error out of the end of the wrapped string is reached.
    raise EOFError, 'end of file reached' if eof?

    # Fill a buffer with the data from the wrapped string.
    buffer = @string.slice(@unbuffered_pos, length)
    # Update the position.
    @unbuffered_pos += buffer.length

    buffer
  end

  def unbuffered_seek(offset, whence = IO::SEEK_SET)
    # Convert the offset and whence into an absolute position.
    case whence
    when IO::SEEK_SET
      new_pos = offset
    when IO::SEEK_CUR
      new_pos = @unbuffered_pos + offset
    when IO::SEEK_END
      new_pos = @string.length + offset
    end

    # Error out if the position is before the beginning of the wrapped string.
    raise Errno::EINVAL, 'Invalid argument' if new_pos < 0

    # Set the new position.
    @unbuffered_pos = new_pos
  end

  def unbuffered_write(string)
    # Pad any space between the end of the wrapped string and the current
    # position with null characters.
    if @unbuffered_pos > @string.length then
      @string << ("\000" * (@unbuffered_pos - @string.length))
    end

    # Insert the new string into the wrapped string, replacing sections as
    # necessary.
    @string = @string.slice(0, @unbuffered_pos) +
              string +
              (@string.slice((@unbuffered_pos + string.length)..-1) || '')

    # Update the position.
    @unbuffered_pos += string.length
  end
end
