# encoding: UTF-8
class IO # :nodoc:
  # This module provides most of the basic input and output functions of
  # <code>IO</code> objects as implemented in Ruby version 1.8.6.  Its use is
  # supported on all versions of Ruby.  See the general documentation of
  # <code>IO::Like</code> for a description of how to create a class capable of
  # using this module.
  #
  # Include this module explicitly rather than <code>IO::Like</code> if the
  # including class should always behave like Ruby 1.8.6 <code>IO</code> no
  # matter what version of Ruby is running the class.
  module Like_1_8_6
    include Enumerable

    # call-seq:
    #   ios << obj           -> ios
    #
    # Writes <i>obj</i> to the stream using #write and returns <i>ios</i>.
    # <i>obj</i> is converted to a <code>String</code> using <code>to_s</code>.
    def <<(obj)
      write(obj)
      self
    end

    # call-seq:
    #   ios.binmode          -> ios
    #
    # Returns <code>self</code>.  Just for compatibility with <code>IO</code>.
    def binmode
      self
    end

    # call-seq:
    #   ios.close            -> nil
    #
    # Arranges for #closed? to return <code>true</code>.  Raises
    # <code>IOError</code> if #closed? already returns <code>true</code>.  For
    # duplexed objects, calls #close_read and #close_write.  For non-duplexed
    # objects, calls #flush if #writable? returns <code>true</code> and then
    # sets a flag so that #closed? will return <code>true</code>.
    def close
      raise IOError, 'closed stream' if closed?
      __io_like__close_read
      flush if writable?
      __io_like__close_write
      nil
    end

    # call-seq:
    #   ios.close_read       -> nil
    #
    # Closes the read end of a duplexed object or the whole object if the object
    # is read-only.
    #
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.  Raises
    # <code>IOError</code> for duplexed objects if called more than once.
    # Raises <code>IOError</code> for non-duplexed objects if #writable? returns
    # <code>true</code>.
    def close_read
      raise IOError, 'closed stream' if closed?
      if __io_like__closed_read? || ! duplexed? && writable? then
        raise IOError, 'closing non-duplex IO for reading'
      end
      if duplexed? then
        __io_like__close_read
      else
        close
      end
      nil
    end

    # call-seq:
    #   ios.close_write      -> nil
    #
    # Closes the write end of a duplexed object or the whole object if the
    # object is write-only.
    #
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.  Raises
    # <code>IOError</code> for duplexed objects if called more than once.
    # Raises <code>IOError</code> for non-duplexed objects if #readable? returns
    # <code>true</code>.
    def close_write
      raise IOError, 'closed stream' if closed?
      if __io_like__closed_write? || ! duplexed? && readable? then
        raise IOError, 'closing non-duplex IO for reading'
      end
      if duplexed? then
        flush
        __io_like__close_write
      else
        close
      end
      nil
    end

    # call-seq:
    #   ios.closed?          -> true or false
    #
    # Returns <code>true</code> if this object is closed or otherwise unusable
    # for read and write operations.
    def closed?
      (__io_like__closed_read? || ! readable?) &&
      (__io_like__closed_write? || ! writable?)
    end

    # call-seq:
    #   ios.duplexed?        -> true or false
    #
    # Returns <code>false</code>.  Override this to return <code>true</code>
    # when creating duplexed <code>IO</code> objects.
    def duplexed?
      false
    end

    # call-seq:
    #   ios.each_byte { |byte| block } -> ios
    #
    # Reads each byte (0..255) from the stream using #getc and calls the given
    # block once for each byte, passing the byte as an argument.
    #
    # <b>NOTE:</b> This method ignores <code>Errno::EAGAIN</code> and
    # <code>Errno::EINTR</code> raised by #unbuffered_read.  Therefore, this
    # method always blocks.  Aside from that exception and the conversion of
    # <code>EOFError</code> results into <code>nil</code> results, this method
    # will also raise the same errors and block at the same times as
    # #unbuffered_read.
    def each_byte
      while (byte = getc) do
        yield(byte)
      end
      self
    end

    # call-seq:
    #   ios.each_line(sep_string = $/) { |line| block } -> ios
    #   ios.each(sep_string = $/) { |line| block } -> ios
    #
    # Reads each line from the stream using #gets and calls the given block once
    # for each line, passing the line as an argument.
    #
    # <b>NOTE:</b> When <i>sep_string</i> is not <code>nil</code>, this method
    # ignores <code>Errno::EAGAIN</code> and <code>Errno::EINTR</code> raised by
    # #unbuffered_read.  Therefore, this method always blocks.  Aside from that
    # exception and the conversion of <code>EOFError</code> results into
    # <code>nil</code> results, this method will also raise the same errors and
    # block at the same times as #unbuffered_read.
    def each_line(sep_string = $/)
      while (line = gets(sep_string)) do
        yield(line)
      end
      self
    end
    alias :each :each_line

    # call-seq:
    #   ios.eof?             -> true or false
    #   ios.eof              -> true or false
    #
    # Returns <code>true</code> if there is no more data to read.
    #
    # This works by using #getc to fetch the next character and using #ungetc to
    # put the character back if one was fetched.  It may be a good idea to
    # replace this implementation in derivative classes.
    #
    # <b>NOTE:</b> This method ignores <code>Errno::EAGAIN</code> and
    # <code>Errno::EINTR</code> raised by #unbuffered_read.  Therefore, this
    # method always blocks.  Aside from that exception and the conversion of
    # <code>EOFError</code> results into <code>nil</code> results, this method
    # will also raise the same errors and block at the same times as
    # #unbuffered_read.
    def eof?
      if (char = getc) then
        ungetc(char)
        return false
      end
      true
    end
    alias :eof :eof?

    # call-seq:
    #   ios.fcntl
    #
    # Raises <code>NotImplementedError</code>.
    def fcntl(*args)
      raise NotImplementedError, 'not implemented'
    end

    # call-seq:
    #   ios.fileno           -> nil
    #
    # Returns <code>nil</code>.  Just for compatibility with <code>IO</code>.
    def fileno
      nil
    end

    # call-seq:
    #   ios.fill_size        -> integer
    #
    # Returns the number of bytes to read as a block whenever the internal
    # buffer needs to be refilled.  Unless set explicitly via #fill_size=, this
    # defaults to <code>4096</code>.
    #
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.  Raises
    # <code>IOError</code> if the stream is not opened for reading.
    def fill_size
      raise IOError, 'closed stream' if closed?
      raise IOError, 'not opened for reading' unless readable?

      @__io_like__fill_size ||= 4096
    end

    # call-seq:
    #   ios.fill_size = integer -> integer
    #
    # Sets the number of bytes to read as a block whenever the internal read
    # buffer needs to be refilled.  The new value must be a number greater than
    # or equal to <code>0</code>.  Setting this to <code>0</code> effectively
    # disables buffering.
    #
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.  Raises
    # <code>IOError</code> if the stream is not opened for reading.
    def fill_size=(fill_size)
      raise IOError, 'closed stream' if closed?
      raise IOError, 'not opened for reading' unless readable?

      unless fill_size >= 0 then
        raise ArgumentError, "non-positive fill_size #{fill_size} given"
      end
      @__io_like__fill_size = fill_size
    end

    # call-seq:
    #   ios.flush            -> ios
    #
    # Flushes the internal write buffer to the underlying data stream.
    #
    # Regardless of the blocking status of the data stream or interruptions
    # during writing, this method will block until either all the data is
    # flushed or until an error is raised.
    #
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.  Raises
    # <code>IOError</code> unless #writable? returns <code>true</code>.
    #
    # <b>NOTE:</b> This method ignores <code>Errno::EAGAIN</code> and
    # <code>Errno::EINTR</code> raised by #unbuffered_write.  Therefore, this
    # method always blocks if unable to flush the internal write buffer.  Aside
    # from that exception, this method will also raise the same errors and block
    # at the same times as #unbuffered_write.
    def flush
      begin
        __io_like__buffered_flush
      rescue Errno::EAGAIN, Errno::EINTR
        retry if write_ready?
      end
      self
    end

    # call-seq:
    #   ios.flush_size       -> integer
    #
    # Returns the number of bytes at which the internal write buffer is flushed
    # automatically to the data stream.  Unless set explicitly via #flush_size=,
    # this defaults to <code>4096</code>.
    #
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.  Raises
    # <code>IOError</code> unless #writable? returns <code>true</code>.
    def flush_size
      raise IOError, 'closed stream' if closed?
      raise IOError, 'not opened for writing' unless writable?

      @__io_like__flush_size ||= 4096
    end

    # call-seq:
    #   ios.flush_size = integer -> integer
    #
    # Sets the number of bytes at which the internal write buffer is flushed
    # automatically to the data stream.  The new value must be a number greater
    # than or equal to <code>0</code>.  Setting this to <code>0</code>
    # effectively disables buffering.
    #
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.  Raises
    # <code>IOError</code> unless #writable? returns <code>true</code>.
    def flush_size=(flush_size)
      raise IOError, 'closed stream' if closed?
      raise IOError, 'not opened for writing' unless writable?

      unless flush_size >= 0 then
        raise ArgumentError, "non-positive flush_size #{flush_size} given"
      end
      @__io_like__flush_size = flush_size
    end

    # call-seq:
    #   ios.fsync
    #
    # Flush data to disk, default is not supported
    def fsync()
      nil
    end

    # call-seq:
    #   ios.getc             -> nil or integer
    #
    # Calls #readchar and either returns the result or <code>nil</code> if
    # #readchar raises <code>EOFError</code>.
    #
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.  Raises
    # <code>IOError</code> unless #readable? returns <code>true</code>.  Raises
    # all errors raised by #unbuffered_read except for <code>EOFError</code>.
    #
    # <b>NOTE:</b> This method ignores <code>Errno::EAGAIN</code> and
    # <code>Errno::EINTR</code> raised by #unbuffered_read.  Therefore, this
    # method always blocks.  Aside from that exception and the conversion of
    # <code>EOFError</code> results into <code>nil</code> results, this method
    # will also raise the same errors and block at the same times as
    # #unbuffered_read.
    def getc
      readchar
    rescue EOFError
      nil
    end

    # call-seq:
    #   ios.gets(sep_string = $/) -> nil or string
    #
    # Calls #readline with <i>sep_string</i> as an argument and either returns
    # the result or <code>nil</code> if #readline raises <code>EOFError</code>.
    # If #readline returns some data, <code>$.</code> is set to the value of
    # #lineno.
    #
    # <b>NOTE:</b> Due to limitations of MRI up to version 1.9.x when running
    # managed (Ruby) code, this method fails to set <code>$_</code> to the
    # returned data; however, other implementations may allow it.
    #
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.  Raises
    # <code>IOError</code> unless #readable? returns <code>true</code>.  Raises
    # all errors raised by #unbuffered_read except for <code>EOFError</code>.
    #
    # <b>NOTE:</b> When <i>sep_string</i> is not <code>nil</code>, this method
    # ignores <code>Errno::EAGAIN</code> and <code>Errno::EINTR</code> raised by
    # #unbuffered_read.  Therefore, this method will always block in that case.
    # Aside from that exception, this method will raise the same errors and
    # block at the same times as #unbuffered_read.
    def gets(sep_string = $/)
      # Set the last read line in the global.
      $_ = readline(sep_string)
      # Set the last line number in the global.
      $. = lineno
      # Return the last read line.
      $_
    rescue EOFError
      nil
    end

    # call-seq:
    #   ios.isatty           -> false
    #
    # Returns <code>false</code>.  Just for compatibility with <code>IO</code>.
    #
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.
    def isatty
      raise IOError, 'closed stream' if closed?
      false
    end
    alias :tty? :isatty

    # call-seq:
    #   ios.lineno           -> integer
    #
    # Returns the number of times #gets was called and returned
    # non-<code>nil</code> data.  By default this is the number of lines read,
    # but calling #gets or any of the other line-based reading methods with a
    # non-default value for <i>sep_string</i> or after changing <code>$/</code>
    # will affect this.
    #
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.  Raises
    # <code>IOError</code> unless #readable? returns <code>true</code>.
    def lineno
      raise IOError, 'closed stream' if closed?
      raise IOError, 'not opened for reading' unless readable?
      @__io_like__lineno ||= 0
    end

    # call-seq:
    #   ios.lineno = lineno  -> lineno
    #
    # Sets the current line number to the given value.  <code>$.</code> is
    # updated by the <i>next</i> call to #gets.  If the object given is not an
    # <code>Integer</code>, it is converted to one using its <code>to_int</code>
    # method.
    #
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.  Raises
    # <code>IOError</code> unless #readable? returns <code>true</code>.
    def lineno=(integer)
      raise IOError, 'closed stream' if closed?
      raise IOError, 'not opened for reading' unless readable?
      if integer.nil? then
        raise TypeError, 'no implicit conversion from nil to integer'
      elsif ! integer.respond_to?(:to_int) then
        raise TypeError, "can't convert #{integer.class} into Integer"
      end
      @__io_like__lineno = integer.to_int
    end

    # call-seq:
    #   ios.nonblock=(blocking_mode)
    #
    # #read_nonblock, #write_nonblock will call nonblock=(true)
    # prior to calling #unbuffered_read or #unbuffered_write
    #
    # The default implementation raises <code>Errno::EBADF</code> to indicate
    # that nonblocking operations are not supported. IO implementations that
    # are always nonblocking should override with a no-op
    def nonblock=(blocking_mode)
      raise Errno::EBADF
    end

    # call-seq:
    #   ios.path             -> nil
    #
    # Returns <code>nil</code>.  Just for compatibility with <code>IO</code>.
    def path
      nil
    end

    # call-seq:
    #   ios.pos = position   -> position
    #
    # Sets the data position to <i>position</i> by calling #seek.
    #
    # As a side effect, the internal read and write buffers are flushed.
    #
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.  Raises
    # <code>Errno::ESPIPE</code> unless #seekable? returns <code>true</code>.
    #
    # <b>NOTE:</b> Because this method relies on #unbuffered_seek and
    # #unbuffered_write (when the internal write buffer is not empty), it will
    # also raise the same errors and block at the same times as those functions.
    def pos=(position)
      seek(position, IO::SEEK_SET)
      position
    end

    # call-seq:
    #   ios.pos              -> integer
    #
    # Returns the current offest of <i>ios</i>.
    #
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.  Raises
    # <code>Errno::ESPIPE</code> unless #seekable? returns <code>true</code>.
    #
    # As a side effect, the internal write buffer is flushed unless this is
    # a writable, non-duplexed object.  This is for compatibility with the
    # behavior of <code>IO#pos</code>.
    #
    # <b>NOTE:</b> Because this method relies on #unbuffered_seek and
    # #unbuffered_write (when the internal write buffer is not empty), it will
    # also raise the same errors and block at the same times as those functions.
    def pos
      # Flush the internal write buffer for writable, non-duplexed objects.
      __io_like__buffered_flush if writable? && ! duplexed?
      __io_like__buffered_seek(0, IO::SEEK_CUR)
    end
    alias :tell :pos

    # call-seq:
    #   ios.print([obj, ...]) -> nil
    #
    # Writes the given object(s), if any, to the stream using #write after
    # converting them to strings by calling their <code>to_s</code> methods.  If
    # no objects are given, <code>$_</code> is used.  The field separator
    # (<code>$,</code>) is written between successive objects if it is not
    # <code>nil</code>.  The output record separator (<code>$\\</code>) is
    # written after all other data if it is not <code>nil</code>.
    #
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.  Raises
    # <code>IOError</code> unless #writable? returns <code>true</code>.
    #
    # <b>NOTE:</b> This method ignores <code>Errno::EAGAIN</code> and
    # <code>Errno::EINTR</code> raised by #unbuffered_write.  Therefore, this
    # method always blocks if unable to immediately write
    # <code>[obj, ...]</code> completely.  Aside from that exception, this
    # method will also raise the same errors and block at the same times as
    # #unbuffered_write.
    def print(*args)
      args << $_ if args.empty?
      first_arg = true
      args.each do |arg|
        # Write a field separator before writing each argument after the first
        # one unless no field separator is specified.
        if first_arg then
          first_arg = false
        elsif ! $,.nil? then
          write($,)
        end

        # If the argument is nil, write 'nil'; otherwise, write the stringified
        # form of the argument.
        if arg.nil? then
          write('nil')
        else
          write(arg)
        end
      end

      # Write the output record separator if one is specified.
      write($\) unless $\.nil?
      nil
    end

    # call-seq:
    #   ios.printf(format_string [, obj, ...]) -> nil
    #
    # Writes the <code>String</code> returned by calling
    # <code>Kernel.sprintf</code> using the given arguments.
    #
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.  Raises
    # <code>IOError</code> unless #writable? returns <code>true</code>.
    #
    # <b>NOTE:</b> This method ignores <code>Errno::EAGAIN</code> and
    # <code>Errno::EINTR</code> raised by #unbuffered_write.  Therefore, this
    # method always blocks if unable to immediately write its arguments
    # completely.  Aside from that exception, this method will also raise the
    # same errors and block at the same times as #unbuffered_write.
    def printf(*args)
      write(sprintf(*args))
      nil
    end

    # call-seq:
    #   ios.putc(obj)        -> obj
    #
    # If <i>obj</i> is a <code>String</code>, write the first byte; otherwise,
    # convert <i>obj</i> to an <code>Integer</code> using its
    # <code>to_int</code> method and write the low order byte.
    #
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.  Raises
    # <code>IOError</code> unless #writable? returns <code>true</code>.
    #
    # <b>NOTE:</b> This method ignores <code>Errno::EAGAIN</code> and
    # <code>Errno::EINTR</code> raised by #unbuffered_write.  Therefore, this
    # method always blocks if unable to immediately write <i>obj</i> completely.
    # Aside from that exception, this method will also raise the same errors and
    # block at the same times as #unbuffered_write.
    def putc(obj)
      char = case obj
             when String
               obj[0].chr
             else
               [obj.to_int].pack('V')[0].chr
             end
      write(char)
      obj
    end

    # call-seq:
    #   ios.puts([obj, ...]) -> nil
    #
    # Writes the given object(s), if any, to the stream using #write after
    # converting them to strings using their <code>to_s</code> methods.  Unlike
    # #print, Array instances are recursively processed.  A record separator
    # character is written after each object which does not end with the record
    # separator already.  If no objects are given, a single record separator is
    # written.
    #
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.  Raises
    # <code>IOError</code> unless #writable? returns <code>true</code>.
    #
    # <b>NOTE:</b> This method ignores <code>Errno::EAGAIN</code> and
    # <code>Errno::EINTR</code> raised by #unbuffered_write.  Therefore, this
    # method always blocks if unable to immediately write
    # <code>[obj, ...]</code> completely.  Aside from that exception, this
    # method will also raise the same errors and block at the same times as
    # #unbuffered_write.
    #
    # <b>NOTE:</b> In order to be compatible with <code>IO#puts</code>, the
    # record separator is currently hardcoded to be a single newline
    # (<code>"\n"</code>) even though the documentation implies that the output
    # record separator (<code>$\\</code>) should be used.
    def puts(*args)
      # Set the output record separator such that this method is compatible with
      # IO#puts.
      ors = "\n"

      # Write only the record separator if no arguments are given.
      if args.length == 0 then
        write(ors)
        return
      end

      # Write each argument followed by the record separator.  Recursively
      # process arguments which are Array instances.
      args.each do |arg|
        line = arg.nil? ?
                 'nil' :
                 arg.kind_of?(Array) ?
                   __io_like__array_join(arg, ors) :
                   arg.to_s
        line += ors if line.index(ors, -ors.length).nil?
        write(line)
      end

      nil
    end

    # call-seq:
    #   ios.read([length[, buffer]]) -> nil, buffer, or string
    #
    # If <i>length</i> is specified and is a positive integer, at most length
    # bytes are returned.  Truncated data will occur if there is insufficient
    # data left to fulfill the request.  If the read starts at the end of data,
    # <code>nil</code> is returned.
    #
    # If <i>length</i> is unspecified or <code>nil</code>, an attempt to return
    # all remaining data is made.  Partial data will be returned if a low-level
    # error is raised after some data is retrieved.  If no data would be
    # returned at all, an empty <code>String</code> is returned.
    #
    # If <i>buffer</i> is specified, it will be converted to a
    # <code>String</code> using its <code>to_str</code> method if necessary and
    # will be filled with the returned data if any.
    #
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.  Raises
    # <code>IOError</code> unless #readable? returns <code>true</code>.
    #
    # <b>NOTE:</b> Because this method relies on #unbuffered_read, it will also
    # raise the same errors and block at the same times as that function.
    def read(length = nil, buffer = nil)
      # Check the validity of the method arguments.
      unless length.nil? || length >= 0 then
        raise ArgumentError, "negative length #{length} given"
      end
      buffer = buffer.nil? ? '' : buffer.to_str
      buffer.slice!(0..-1) unless buffer.empty?

      if length.nil? then
        # Read and return everything.
        begin
          loop do
            buffer << __io_like__buffered_read(4096)
          end
        rescue EOFError
          # Ignore this.
        rescue SystemCallError
          # Reraise the error if there is nothing to return.
          raise if buffer.empty?
        end
      else
        # Read and return up to length bytes.
        begin
          buffer << __io_like__buffered_read(length)
        rescue EOFError
          # Return nil to the caller at end of file when requesting a specific
          # amount of data.
          return nil
        end
      end
      buffer
    end

    # call-seq:
    #   ios.read_ready?      -> true or false
    #
    # Returns <code>true</code> when the stream may be read without error,
    # <code>false</code> otherwise.  This method will block until one of the
    # conditions is known.
    #
    # This default implementation of #read_ready? is a hack which should be able
    # to work for both real <code>IO</code> objects and <code>IO</code>-like
    # objects; however, it is inefficient since it merely sleeps for 1 second
    # and then returns <code>true</code> as long as #readable? returns
    # <code>true</code>.  <code>IO.select</code> should be used for real
    # <code>IO</code> objects to wait for a readable condition on platforms with
    # support for <code>IO.select</code>.  Other solutions should be found as
    # necessary to improve this implementation on a case by case basis.
    #
    # Basically, this method should be overridden in derivative classes.
    def read_ready?
      return false unless readable?
      sleep(1)
      true
    end

    # call-seq:
    #   ios.readable?        -> true or false
    #
    # Returns <code>true</code> if the stream is both open and readable,
    # <code>false</code> otherwise.
    #
    # This implementation checks to see if #unbuffered_read is defined in order
    # to make its determination.  Override this if the implementing class always
    # provides the #unbuffered_read method but may not always be open in a
    # readable mode.
    def readable?
      ! __io_like__closed_read? && respond_to?(:unbuffered_read, true)
    end

    # call-seq:
    #   ios.readbytes(length) -> string
    #
    # Reads and returns <i>length</i> bytes from the data stream.
    #
    # Raises <code>EOFError</code> if reading begins at the end of the stream.
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.
    # Raises <code>IOError</code> unless #readable? returns <code>true</code>.
    # Raises <code>TruncatedDataError</code> if insufficient data is immediately
    # available to satisfy the request.
    #
    # In the case of <code>TruncatedDataError</code> being raised, the retrieved
    # data can be fetched from the <code>data</code> attribute of the exception.
    #
    # This method is basically copied from <code>IO#readbytes</code>.
    #
    # <b>NOTE:</b> Because this method relies on #unbuffered_read, it will also
    # raise the same errors and block at the same times as that function.
    def readbytes(length)
      buffer = read(length)
      if buffer.nil? then
        raise EOFError, "end of file reached"
      end
      if buffer.length < length then
        raise TruncatedDataError.new("data truncated", buffer)
      end
      buffer
    end

    # call-seq:
    #   ios.readchar         -> integer
    #
    # Returns the next 8-bit byte (0..255) from the stream.
    #
    # Raises <code>EOFError</code> when there is no more data in the stream.
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.  Raises
    # <code>IOError</code> unless #readable? returns <code>true</code>.
    #
    # <b>NOTE:</b> This method ignores <code>Errno::EAGAIN</code> and
    # <code>Errno::EINTR</code> raised by #unbuffered_read.  Therefore, this
    # method always blocks.  Aside from that exception, this method will also
    # raise the same errors and block at the same times as #unbuffered_read.
    def readchar
      __io_like__buffered_read(1)[0]
    rescue Errno::EAGAIN, Errno::EINTR
      retry if read_ready?
    end

    # call-seq:
    #   ios.readline(sep_string = $/) -> string
    #
    # Returns the next line from the stream, where lines are separated by
    # <i>sep_string</i>.  Increments #lineno by <code>1</code> for each call
    # regardless of the value of <i>sep_string</i>.
    #
    # If <i>sep_string</i> is not <code>nil</code> and not a
    # <code>String</code>, it is first converted to a <code>String</code> using
    # its <code>to_str</code> method and processing continues as follows.
    #
    # If <i>sep_string</i> is <code>nil</code>, a line is defined as the
    # remaining contents of the stream.  Partial data will be returned if a
    # low-level error of any kind is raised after some data is retrieved.  This
    # is equivalent to calling #read without any arguments except that this
    # method will raise an <code>EOFError</code> if called at the end of the
    # stream.
    #
    # If <i>sep_string</i> is an empty <code>String</code>, a paragraph is
    # returned, where a paragraph is defined as data followed by 2 or more
    # successive newline characters.  A maximum of 2 newlines are returned at
    # the end of the returned data.  Fewer may be returned if the stream ends
    # before at least 2 successive newlines are seen.
    #
    # Any other value for <i>sep_string</i> is used as a delimiter to mark the
    # end of a line.  The returned data includes this delimiter unless the
    # stream ends before the delimiter is seen.
    #
    # In any case, the end of the stream terminates the current line.
    #
    # Raises <code>EOFError</code> when there is no more data in the stream.
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.  Raises
    # <code>IOError</code> unless #readable? returns <code>true</code>.
    #
    # <b>NOTE:</b> When <i>sep_string</i> is not <code>nil</code>, this method
    # ignores <code>Errno::EAGAIN</code> and <code>Errno::EINTR</code> raised by
    # #unbuffered_read.  Therefore, this method will always block in that case.
    # Aside from that exception, this method will raise the same errors and
    # block at the same times as #unbuffered_read.
    def readline(sep_string = $/)
      # Ensure that sep_string is either nil or a String.
      unless sep_string.nil? || sep_string.kind_of?(String) then
        sep_string = sep_string.to_str
      end

      buffer = ''
      begin
        if sep_string.nil? then
          # A nil line separator means that the user wants to capture all the
          # remaining input.
          loop do
            buffer << __io_like__buffered_read(4096)
          end
        else
          begin
            # Record if the user requested paragraphs rather than lines.
            paragraph_requested = sep_string.empty?
            # An empty line separator string indicates that the user wants to
            # return paragraphs.  A pair of newlines in the stream is used to
            # mark this.
            sep_string = "\n\n" if paragraph_requested

            if paragraph_requested then
              # If the user requested paragraphs instead of lines, we need to
              # consume and discard all newlines remaining at the front of the
              # input.
              char = __io_like__buffered_read(1)
              char = __io_like__buffered_read(1) while char == "\n"
              # Put back the last character.
              ungetc(char[0])
            end

            # Add each character from the input to the buffer until either the
            # buffer has the right ending or the end of the input is reached.
            while buffer.index(sep_string, -sep_string.length).nil? do
              buffer << __io_like__buffered_read(1)
            end

            if paragraph_requested then
              # If the user requested paragraphs instead of lines, we need to
              # consume and discard all newlines remaining at the front of the
              # input.
              char = __io_like__buffered_read(1)
              char = __io_like__buffered_read(1) while char == "\n"
              # Put back the last character.
              ungetc(char[0])
            end
          rescue Errno::EAGAIN, Errno::EINTR
            retry if read_ready?
          end
        end
      rescue EOFError, SystemCallError
        # Reraise the error if there is nothing to return.
        raise if buffer.empty?
      end
      # Increment the number of times this method has returned a "line".
      self.lineno += 1
      buffer
    end

    # call-seq:
    #   ios.readlines(sep_string = $/) -> array
    #
    # Returns an <code>Array</code> containing the lines in the stream using
    # #each_line.
    #
    # If <i>sep_string</i> is <code>nil</code>, a line is defined as the
    # remaining contents of the stream.  If <i>sep_string</i> is not a
    # <code>String</code>, it is converted to one using its <code>to_str</code>
    # method.  If <i>sep_string</i> is empty, a paragraph is returned, where a
    # paragraph is defined as data followed by 2 or more successive newline
    # characters (only 2 newlines are returned at the end of the returned data).
    #
    # In any case, the end of the stream terminates the current line.
    #
    # Raises <code>EOFError</code> when there is no more data in the stream.
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.  Raises
    # <code>IOError</code> unless #readable? returns <code>true</code>.
    #
    # <b>NOTE:</b> When <i>sep_string</i> is not <code>nil</code>, this method
    # ignores <code>Errno::EAGAIN</code> and <code>Errno::EINTR</code> raised by
    # #unbuffered_read.  Therefore, this method always blocks.  Aside from that
    # exception, this method will also raise the same errors and block at the
    # same times as #unbuffered_read.
    def readlines(sep_string = $/)
      lines = []
      each_line(sep_string) { |line| lines << line }
      lines
    end

    # call-seq:
    #   ios.read_nonblock(length[, buffer]) -> string or buffer
    #
    # Returns at most <i>length</i> bytes from the data stream using only the
    # internal read buffer if the buffer is not empty.
    #
    # If internal buffer is empty sets nonblocking mode via #nonblock=(true)
    # and then reads from the underlying stream
    #
    # Raises <code>Errno::EBADF</code> if nonblocking mode is not supported
    # Raises <code>EOFError</code> when there is no more data in the stream.
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.
    # Raises <code>IOError</code> unless #readable? returns <code>true</code>.
    #
    # This method will raise errors directly from #buffered_read to be handled
    # by the caller.
    #
    def read_nonblock(length, buffer = nil)
      __io_like__readpartial(length,buffer,true)
    end

    # call-seq:
    #   ios.readpartial(length[, buffer]) -> string or buffer
    #
    # Returns at most <i>length</i> bytes from the data stream using only the
    # internal read buffer if the buffer is not empty.  Falls back to reading
    # from the stream if the buffer is empty.  Blocks if no data is available
    # from either the internal read buffer or the data stream regardless of
    # whether or not the data stream would block.
    #
    # Raises <code>EOFError</code> when there is no more data in the stream.
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.  Raises
    # <code>IOError</code> unless #readable? returns <code>true</code>.
    #
    # <b>NOTE:</b> This method ignores <code>Errno::EAGAIN</code> and
    # <code>Errno::EINTR</code> raised by #unbuffered_read.  Therefore, this
    # method always blocks (via #read_ready?) if unable to immediately return <i>length</i> bytes.
    # Aside from that exception, this method will also raise the same errors and
    # block at the same times as #unbuffered_read.
    def readpartial(length, buffer = nil)
        __io_like__readpartial(length,buffer,false)
    end

    # call-seq:
    #   ios.rewind           -> 0
    #
    # Sets the position of the file pointer to the beginning of the stream and
    # returns <code>0</code> when complete.  The <code>lineno</code> attribute
    # is reset to <code>0</code> if successful and the stream is readable
    # according to #readable?.
    #
    # As a side effect, the internal read and write buffers are flushed.
    #
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.  Raises
    # <code>Errno::ESPIPE</code> unless #seekable? returns <code>true</code>.
    #
    # <b>NOTE:</b> Because this method relies on #unbuffered_seek and
    # #unbuffered_write (when the internal write buffer is not empty), it will
    # also raise the same errors and block at the same times as those functions.
    def rewind
      seek(0, IO::SEEK_SET)
      self.lineno = 0 if readable?
      0
    end

    # call-seq:
    #   seek(offset[, whence]) -> 0
    #
    # Sets the current data position to <i>offset</i> based on the setting of
    # <i>whence</i>.  If <i>whence</i> is unspecified or
    # <code>IO::SEEK_SET</code>, <i>offset</i> counts from the beginning of the
    # data.  If <i>whence</i> is <code>IO::SEEK_END</code>, <i>offset</i> counts
    # from the end of the data (<i>offset</i> should be negative here).  If
    # <i>whence</i> is <code>IO::SEEK_CUR</code>, <i>offset</i> is relative to
    # the current position.
    #
    # As a side effect, the internal read and write buffers are flushed except
    # when seeking relative to the current position (whence is
    # <code>IO::SEEK_CUR</code>) to a location within the internal read buffer.
    #
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.  Raises
    # <code>Errno::ESPIPE</code> unless #seekable? returns <code>true</code>.
    #
    # <b>NOTE:</b> Because this method relies on #unbuffered_seek and
    # #unbuffered_write (when the internal write buffer is not empty), it will
    # also raise the same errors and block at the same times as those functions.
    def seek(offset, whence = IO::SEEK_SET)
      __io_like__buffered_seek(offset, whence)
      0
    end

    # call-seq:
    #   ios.seekable?        -> true or false
    #
    # Returns <code>true</code> if the stream is seekable, <code>false</code>
    # otherwise.
    #
    # This implementation always returns <code>false</code> for duplexed objects
    # and checks to see if #unbuffered_seek is defined in order to make its
    # determination otherwise.  Override this if the implementing class always
    # provides the #unbuffered_seek method but may not always be seekable.
    def seekable?
      ! duplexed? && respond_to?(:unbuffered_seek, true)
    end

    # call-seq:
    #   ios.sync             -> true or false
    #
    # Returns <code>true</code> if the internal write buffer is currently being
    # bypassed, <code>false</code> otherwise.
    #
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.
    def sync
      raise IOError, 'closed stream' if closed?
      @__io_like__sync ||= false
    end

    # call-seq:
    #   ios.sync = boolean   -> boolean
    #
    # When set to <code>true</code> the internal write buffer will be bypassed.
    # Any data currently in the buffer will be flushed prior to the next output
    # operation.  When set to <code>false</code>, the internal write buffer will
    # be enabled.
    #
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.
    def sync=(sync)
      raise IOError, 'closed stream' if closed?
      @__io_like__sync = sync ? true : false
    end

    # call-seq:
    #   ios.sysread(length)  -> string
    #
    # Reads and returns up to <i>length</i> bytes directly from the data stream,
    # bypassing the internal read buffer.
    #
    # Returns <code>""</code> if <i>length</i> is <code>0</code> regardless of
    # the status of the data stream.  This is for compatibility with
    # <code>IO#sysread</code>.
    #
    # Raises <code>EOFError</code> if reading begins at the end of the stream.
    # Raises <code>IOError</code> if the internal read buffer is not empty.
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.
    #
    # <b>NOTE:</b> Because this method relies on #unbuffered_read, it will also
    # raise the same errors and block at the same times as that function.
    def sysread(length, buffer = nil)
      buffer = buffer.nil? ? '' : buffer.to_str
      buffer.slice!(0..-1) unless buffer.empty?
      return buffer if length == 0

      raise IOError, 'closed stream' if closed?
      raise IOError, 'not opened for reading' unless readable?
      unless __io_like__internal_read_buffer.empty? then
        raise IOError, 'sysread on buffered IO'
      end

      # Flush the internal write buffer for writable, non-duplexed objects.
      __io_like__buffered_flush if writable? && ! duplexed?

      buffer << unbuffered_read(length)
    end

    # call-seq:
    #   ios.sysseek(offset[, whence]) -> integer
    #
    # Sets the current data position to <i>offset</i> based on the setting of
    # <i>whence</i>.  If <i>whence</i> is unspecified or
    # <code>IO::SEEK_SET</code>, <i>offset</i> counts from the beginning of the
    # data.  If <i>whence</i> is <code>IO::SEEK_END</code>, <i>offset</i> counts
    # from the end of the data (<i>offset</i> should be negative here).  If
    # <i>whence</i> is <code>IO::SEEK_CUR</code>, <i>offset</i> is relative to
    # the current position.
    #
    # Raises <code>IOError</code> if the internal read buffer is not empty.
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.  Raises
    # <code>Errno::ESPIPE</code> unless #seekable? returns <code>true</code>.
    #
    # <b>NOTE:</b> Because this method relies on #unbuffered_seek, it will also
    # raise the same errors and block at the same times as that function.
    def sysseek(offset, whence = IO::SEEK_SET)
      raise IOError, 'closed stream' if closed?
      raise Errno::ESPIPE unless seekable?
      unless __io_like__internal_read_buffer.empty? then
        raise IOError, 'sysseek on buffered IO'
      end
      unless __io_like__internal_write_buffer.empty? then
        warn('warning: sysseek on buffered IO')
      end

      unbuffered_seek(offset, whence)
    end

    # call-seq:
    #   ios.syswrite(string) -> integer
    #
    # Writes <i>string</i> directly to the data stream, bypassing the internal
    # write buffer and returns the number of bytes written.
    #
    # As a side effect for non-duplex objects, the internal read buffer is
    # flushed.
    #
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.  Raises
    # <code>IOError</code> unless #writable? returns <code>true</code>.
    #
    # <b>NOTE:</b> Because this method relies on #unbuffered_write, it will also
    # raise the same errors and block at the same times as that function.
    def syswrite(string)
      raise IOError, 'closed stream' if closed?
      raise IOError, 'not opened for writing' unless writable?
      unless __io_like__internal_write_buffer.empty? then
        warn('warning: syswrite on buffered IO')
      end

      # Flush the internal read buffer and set the unbuffered position to the
      # buffered position when dealing with non-duplexed objects.
      unless duplexed? || __io_like__internal_read_buffer.empty? then
        unbuffered_seek(-__io_like__internal_read_buffer.length, IO::SEEK_CUR)
        __io_like__internal_read_buffer.slice!(0..-1)
      end

      unbuffered_write(string)
    end

    # call-seq:
    #   ios.to_io            -> ios
    #
    # Returns <i>ios</i>.
    def to_io
      self
    end

    # call-seq:
    #   ios.ungetc(integer)  -> nil
    #
    # Calls #unread with <code>integer.chr</code> as an argument.
    #
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.  Raises
    # <code>IOError</code> unless #readable? returns <code>true</code>.
    def ungetc(integer)
      unread(integer.chr)
    end

    # call-seq:
    #   ios.unread(string)  -> nil
    #
    # Pushes the given string onto the front of the internal read buffer and
    # returns <code>nil</code>.  If <i>string</i> is not a <code>String</code>,
    # it is converted to one using its <code>to_s</code> method.
    #
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.  Raises
    # <code>IOError</code> unless #readable? returns <code>true</code>.
    def unread(string)
      raise IOError, 'closed stream' if closed?
      raise IOError, 'not opened for reading' unless readable?
      __io_like__internal_read_buffer.insert(0, string.to_s)
      nil
    end

    # call-seq:
    #   ios.write_ready?        -> true or false
    #
    # Returns <code>true</code> when the stream may be written without error,
    # <code>false</code> otherwise.  This method will block until one of the
    # conditions is known.
    #
    # This default implementation of #write_ready? is a hack which should be
    # able to work for both real <code>IO</code> objects and
    # <code>IO</code>-like objects; however, it is inefficient since it merely
    # sleeps for 1 second and then returns <code>true</code> as long as #closed?
    # returns <code>false</code>.  <code>IO.select</code> should be used for
    # real <code>IO</code> objects to wait for a writeable condition on
    # platforms with support for <code>IO.select</code>.  Other solutions should
    # be found as necessary to improve this implementation on a case by case
    # basis.
    #
    # Basically, this method should be overridden in derivative classes.
    def write_ready?
      return false unless writable?
      sleep(1)
      true
    end

    # call-seq:
    #   ios.writable?        -> true or false
    #
    # Returns <code>true</code> if the stream is both open and writable,
    # <code>false</code> otherwise.
    #
    # This implementation checks to see if #unbuffered_write is defined in order
    # to make its determination.  Override this if the implementing class always
    # provides the #unbuffered_write method but may not always be open in a
    # writable mode.
    def writable?
      ! __io_like__closed_write? && respond_to?(:unbuffered_write, true)
    end

    # call-seq:
    #   ios.write(string)    -> integer
    #
    # Writes the given string to the stream and returns the number of bytes
    # written.  If <i>string</i> is not a <code>String</code>, its
    # <code>to_s</code> method is used to convert it into one.  The entire
    # contents of <i>string</i> are written, blocking as necessary even if the
    # data stream does not block.
    #
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.  Raises
    # <code>IOError</code> unless #writable? returns <code>true</code>.
    #
    # <b>NOTE:</b> This method ignores <code>Errno::EAGAIN</code> and
    # <code>Errno::EINTR</code> raised by #unbuffered_write.  Therefore, this
    # method always blocks if unable to immediately write <i>string</i>
    # completely.  Aside from that exception, this method will also raise the
    # same errors and block at the same times as #unbuffered_write.
    def write(string)
      string = string.to_s
      return 0 if string.empty?

      bytes_written = 0
      while bytes_written < string.length do
        begin
          bytes_written +=
            __io_like__buffered_write(string.to_s.slice(bytes_written..-1),false)
        rescue Errno::EAGAIN, Errno::EINTR
          retry if write_ready?
        end
      end
      bytes_written
    end

    # call-seq:
    #   ios.write_nonblock(string)    -> integer
    #
    # Writes the given string to the stream and returns the number of bytes
    # written.  If <i>string</i> is not a <code>String</code>, its
    # <code>to_s</code> method is used to convert it into one.
    #
    # As many bytes as possible are written without blocking or
    # SystemCallEerror from #unbuffered_write is passed directly through
    # to be handled by the caller
    #
    # Raises <code>IOError</code> if #closed? returns <code>true</code>.  Raises
    # <code>IOError</code> unless #writable? returns <code>true</code>.
    def write_nonblock(string)
      string = string.to_s
      return 0 if string.empty?

      return __io_like__buffered_write(string,true)
    end

    private

    # call-seq:
    #   ios.__io_like__buffered_flush   -> 0
    #
    # Attempts to completely flush the internal write buffer to the data stream.
    #
    # Raises <code>IOError</code> unless #writable? returns <code>true</code>.
    #
    # <b>NOTE:</b> Because this method relies on #unbuffered_write, it raises
    # all errors raised by #unbuffered_write and blocks when #unbuffered_write
    # blocks.
    def __io_like__buffered_flush
      raise IOError, 'closed stream' if closed?
      raise IOError, 'not opened for writing' unless writable?

      until __io_like__internal_write_buffer.empty? do
        __io_like__internal_write_buffer.slice!(
          0, unbuffered_write(__io_like__internal_write_buffer)
        )
      end
      0
    end

    # call-seq:
    #   ios.__io_like__buffered_read(length) -> string
    #
    # Reads at most <i>length</i> bytes first from an internal read buffer
    # followed by the underlying stream if necessary and returns the resulting
    # buffer.
    #
    # Raises <code>EOFError</code> if the internal read buffer is empty and
    # reading begins at the end of the stream.  Raises <code>IOError</code>
    # unless #readable? returns <code>true</code>.
    #
    # <b>NOTE:</b> Because this method relies on #unbuffered_read, it raises all
    # errors raised by #unbuffered_read and blocks when #unbuffered_read blocks
    # whenever the internal read buffer is unable to fulfill the request.
    def __io_like__buffered_read(length)
      # Check the validity of the method arguments.
      raise ArgumentError, "non-positive length #{length} given" if length < 0

      raise IOError, 'closed stream' if closed?
      raise IOError, 'not opened for reading' unless readable?

      # Flush the internal write buffer for writable, non-duplexed objects.
      __io_like__buffered_flush if writable? && ! duplexed?

      # Ensure that the internal read buffer has at least enough data to satisfy
      # the request.
      if __io_like__internal_read_buffer.length < length then
        unbuffered_length = length - __io_like__internal_read_buffer.length
        unbuffered_length = fill_size if unbuffered_length < fill_size

        begin
          __io_like__internal_read_buffer << unbuffered_read(unbuffered_length)
        rescue EOFError, SystemCallError
          # Reraise the error if there is no data to return.
          raise if __io_like__internal_read_buffer.empty?
        end
      end

      # Read from the internal read buffer.
      buffer = __io_like__internal_read_buffer.slice!(0, length)

      buffer
    end

    # call-seq:
    #   ios.__io_like__readpartial(length,buffer,nonblock) -> string
    #
    # #read_nonblock and #read_partial are identical except for
    # the way they handle exceptions from #unbuffered_read.
    def __io_like__readpartial(length,buffer,nonblock)
      # Check the validity of the method arguments.
      unless length >= 0 then
        raise ArgumentError, "negative length #{length} given"
      end
      buffer = '' if buffer.nil?
      # Flush the buffer.
      buffer.slice!(0..-1)

      # set nonblocking if necessary
      __io_like__nonblock if nonblock

      # Read and return up to length bytes.
      if __io_like__internal_read_buffer.empty? then
        begin
          buffer << __io_like__buffered_read(length)
        rescue Errno::EINTR, Errno::EAGAIN
          if !nonblock && read_ready? then retry else raise end
        end
      else
        raise IOError, 'closed stream' if closed?
        raise IOError, 'not opened for reading' unless readable?

        buffer << __io_like__internal_read_buffer.slice!(0, length)
      end
      buffer
    end

    # call-seq:
    #   ios.__io_like__nonblock()
    #
    # Puts the underlying stream into blocking mode
    #
    # See #read_nonblock, #write_nonblock #nonblock=
    def __io_like__nonblock
      self.nonblock=(true)
    end

    # call-seq:
    #   ios.__io_like__buffered_seek(offset[, whence]) -> integer
    #
    # Sets the current data position to <i>offset</i> based on the setting of
    # <i>whence</i>.  If <i>whence</i> is unspecified or
    # <code>IO::SEEK_SET</code>, <i>offset</i> counts from the beginning of the
    # data.  If <i>whence</i> is <code>IO::SEEK_END</code>, <i>offset</i> counts
    # from the end of the data (<i>offset</i> should be negative here).  If
    # <i>whence</i> is <code>IO::SEEK_CUR</code>, <i>offset</i> is relative to
    # the current position.
    #
    # As a side effect, the internal read and write buffers are flushed except
    # when seeking relative to the current position (whence is
    # <code>IO::SEEK_CUR</code>) to a location within the internal read buffer.
    #
    # Raises <code>Errno::ESPIPE</code> unless #seekable? returns
    # <code>true</code>.
    #
    # See #seek for the usage of <i>offset</i> and <i>whence</i>.
    #
    # <b>NOTE:</b> Because this method relies on #unbuffered_seek and
    # #unbuffered_write (when the internal write buffer is not empty), it will
    # raise the same errors and block at the same times as those functions.
    def __io_like__buffered_seek(offset, whence = IO::SEEK_SET)
      raise IOError, 'closed stream' if closed?
      raise Errno::ESPIPE unless seekable?

      if whence == IO::SEEK_CUR && offset == 0 then
        # The seek is only determining the current position, so return the
        # buffered position based on the read buffer if it's not empty and the
        # write buffer otherwise.
        __io_like__internal_read_buffer.empty? ?
          unbuffered_seek(0, IO::SEEK_CUR) +
            __io_like__internal_write_buffer.length :
          unbuffered_seek(0, IO::SEEK_CUR) -
            __io_like__internal_read_buffer.length
      elsif whence == IO::SEEK_CUR && offset > 0 &&
            __io_like__internal_write_buffer.empty? &&
            offset <= __io_like__internal_read_buffer.length then
        # The seek is within the read buffer, so just discard a sufficient
        # amount of the buffer and report the new buffered position.
        __io_like__internal_read_buffer.slice!(0, offset)
        unbuffered_seek(0, IO::SEEK_CUR) -
          __io_like__internal_read_buffer.length
      else
        # The seek target is outside of the buffers, so flush the buffers and
        # jump to the new position.
        if whence == IO::SEEK_CUR then
          # Adjust relative offsets based on the current buffered offset.
          offset += __io_like__internal_read_buffer.empty? ?
            __io_like__internal_write_buffer.length :
            -__io_like__internal_read_buffer.length
        end

        # Flush the internal buffers.
        __io_like__internal_read_buffer.slice!(0..-1)
        __io_like__buffered_flush if writable?

        # Move the data stream's position as requested.
        unbuffered_seek(offset, whence)
      end
    end

    # call-seq:
    #   ios.__io_like__buffered_write(string) -> integer
    #
    # Writes <i>string</i> to the internal write buffer and returns the number
    # of bytes written.  If the internal write buffer is overfilled by
    # <i>string</i>, it is repeatedly flushed until that last of <i>string</i>
    # is consumed.  A partial write will occur if part of <i>string</i> fills
    # the internal write buffer but the internal write buffer cannot be
    # immediately flushed due to the underlying stream not blocking when unable
    # to accept more data.
    #
    # <b>NOTE:</b> Because this method relies on #unbuffered_write, it raises
    # all errors raised by #unbuffered_write and blocks when #unbuffered_write
    # blocks whenever the internal write buffer is unable to fulfill the
    # request.
    def __io_like__buffered_write(string,nonblock=false)
      raise IOError, 'closed stream' if closed?
      raise IOError, 'not opened for writing' unless writable?

      # Flush the internal read buffer and set the unbuffered position to the
      # buffered position when dealing with non-duplexed objects.
      unless duplexed? || __io_like__internal_read_buffer.empty? then
        unbuffered_seek(-__io_like__internal_read_buffer.length, IO::SEEK_CUR)
        __io_like__internal_read_buffer.slice!(0..-1)
      end

      bytes_written = 0

      if sync || nonblock || __io_like__internal_write_buffer.length + string.length >= flush_size then
        # Flush the internal write buffer and then bypass it when in synchronous
        # mode or the tipping point for the write buffer would be surpassed by this
        # request.
        __io_like__nonblock() if nonblock
        __io_like__buffered_flush
        bytes_written = unbuffered_write(string)
      else
        # The buffer can absorb the entire request.
        __io_like__internal_write_buffer << string
        bytes_written = string.length
      end
      return bytes_written
    end

    # Returns a reference to the internal read buffer.
    def __io_like__internal_read_buffer
      @__io_like__read_buffer ||= ''
    end

    # Returns a reference to the internal write buffer.
    def __io_like__internal_write_buffer
      @__io_like__write_buffer ||= ''
    end

    # Returns <code>true</code> if this object has been closed for reading;
    # otherwise, returns <code>false</code>.
    def __io_like__closed_read?
      @__io_like__closed_read ||= false
    end

    # Arranges for #__io_like__closed_read? to return <code>true</code>.
    def __io_like__close_read
      @__io_like__closed_read = true
      nil
    end

    # Returns <code>true</code> if this object has been closed for writing;
    # otherwise, returns <code>false</code>.
    def __io_like__closed_write?
      @__io_like__closed_write ||= false
    end

    # Arranges for #__io_like__closed_write? to return <code>true</code>.
    def __io_like__close_write
      @__io_like__closed_write = true
      nil
    end

    # This method joins the elements of <i>array</i> together with _separator_
    # between each element and returns the result.  <i>seen</i> is a list of
    # object IDs representing arrays which have already started processing.
    #
    # This method exists only because Array#join apparently behaves in an
    # implementation dependent manner when joining recursive arrays and so does
    # not always produce the expected results.  Specifically, MRI 1.8.6 and
    # 1.8.7 behave as follows:
    #
    #   x = []
    #   x << 1 << x << 2
    #   x.join(', ')              => "1, 1, [...], 2, 2"
    #
    # The expected and necessary result for use with #puts is:
    #
    #   "1, [...], 2"
    #
    # Things get progressively worse as the nesting and recursion become more
    # convoluted.
    def __io_like__array_join(array, separator, seen = [])
      seen.push(array.object_id)
      need_separator = false
      result = array.inject('') do |memo, item|
        memo << separator if need_separator
        need_separator = true

        memo << if item.kind_of?(Array) then
                  if seen.include?(item.object_id) then
                    '[...]'
                  else
                    __io_like__array_join(item, separator, seen)
                  end
                else
                  item.to_s
                end
      end
      seen.pop

      result
    end
  end
end

# vim: ts=2 sw=2 et
