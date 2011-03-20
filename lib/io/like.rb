# encoding: UTF-8
# Set the implementation of IO::Like based on the version of the Ruby
# interpreter reading this file.
ver_arr = RUBY_VERSION.split('.').collect { |n| n.to_i }
if (ver_arr <=> [1, 8, 6]) <= 0 then
  require 'io/like-1.8.6'
  IO::Like = IO::Like_1_8_6
else
  require 'io/like-1.8.7'
  IO::Like = IO::Like_1_8_7
end

# Redefine IO::Like here in order to get rdoc documentation generated for it.
class IO # :nodoc:
  # IO::Like is a module which provides most of the basic input and output
  # functions of IO objects using methods named _unbuffered_read_,
  # _unbuffered_write_, and _unbuffered_seek_.
  #
  # The definition of this particular module is equivalent to whatever
  # version-specific module provides the closest interface to the IO
  # implementation of the Ruby interpreter running this library.  For example,
  # IO::Like will be equivalent to IO::Like_1_8_6 under Ruby version 1.8.6 while
  # it will be equivalent to IO::Like_1_8_7 under Ruby version 1.8.7.
  #
  # When considering any of the IO::Like modules for use in a class, the
  # following documentation holds true.
  #
  # == Readers
  #
  # In order to use this module to provide input methods, a class which
  # includes it must provide the _unbuffered_read_ method which takes one
  # argument, a length, as follows:
  #
  #   def unbuffered_read(length)
  #     ...
  #   end
  #
  # This method must return at most _length_ bytes as a String, raise EOFError
  # if reading begins at the end of data, and raise SystemCallError on error.
  # Errno::EAGAIN should be raised if there is no data to return immediately and
  # the read operation should not block.  Errno::EINTR should be raised if the
  # read operation is interrupted before any data is read.
  #
  # == Writers
  #
  # In order to use this module to provide output methods, a class which
  # includes it must provide the _unbuffered_write_ method which takes a single
  # string argument as follows:
  #
  #   def unbuffered_write(string)
  #     ...
  #   end
  #
  # This method must either return the number of bytes written to the stream,
  # which may be less than the length of _string_ in bytes, OR must raise an
  # instance of SystemCallError.  Errno::EAGAIN should be raised if no data can
  # be written immediately and the write operation should not block.
  # Errno::EINTR should be raised if the write operation is interrupted before
  # any data is written.
  #
  # == Seekers
  #
  # In order to use this module to provide seeking methods, a class which
  # includes it must provide the _unbuffered_seek_ method which takes two
  # required arguments, an offset and a start position, as follows:
  #
  #   def unbuffered_seek(offset, whence)
  #     ...
  #   end
  #
  # This method must return the new position within the data stream relative to
  # the beginning of the stream and should raise SystemCallError on error.
  # _offset_ can be any integer and _whence_ can be any of IO::SEEK_SET,
  # IO::SEEK_CUR, or IO::SEEK_END.  They are interpreted together as follows:
  #
  #         whence | resulting position
  #   -------------+------------------------------------------------------------
  #   IO::SEEK_SET | Add offset to the position of the beginning of the stream.
  #   -------------+------------------------------------------------------------
  #   IO::SEEK_CUR | Add offset to the current position of the stream.
  #   -------------+------------------------------------------------------------
  #   IO::SEEK_END | Add offset to the position of the end of the stream.
  #
  # == Duplexed Streams
  #
  # In order to create a duplexed stream where writing and reading happen
  # independently of each other, override the #duplexed? method to return
  # +true+ and then provide the _unbuffered_read_ and _unbuffered_write_
  # methods.  Do *NOT* provide an _unbuffered_seek_ method or the contents of
  # the internal read and write buffers may be lost unexpectedly.
  # ---
  # <b>NOTE:</b> Due to limitations of Ruby's finalizer, IO::Like#close is not
  # automatically called when the object is garbage collected, so it must be
  # explicitly called when the object is no longer needed or risk losing
  # whatever data remains in the internal write buffer.
  module Like
  end
end

# vim: ts=2 sw=2 et
