# encoding: UTF-8

$: << File.expand_path('../../../lib', __FILE__)

require 'mspec/helpers/io'
require 'mspec/matchers/output_to_fd'

require 'io/like'
require 'io/like_helpers/buffered_io'
require 'io/like_helpers/io_wrapper'

class Object
  def io_like_parse_io_settings(mode = nil, perm = nil, **kwargs)
    raise 'mode specified twice' if mode && kwargs[:mode]

    result = {}

    mode ||= kwargs[:mode]
    result.merge!(io_like_parse_mode_string(mode)) unless Integer === mode

    case kwargs[:encoding]
    when String
      result[:external_encoding], result[:internal_encoding] =
        kwargs[:encoding].split(':')
    when Encoding
      result[:external_encoding] = kwargs[:encoding]
    end

    if kwargs.key?(:external_encoding)
      result[:external_encoding] = kwargs[:external_encoding]
    end
    if kwargs.key?(:internal_encoding)
      result[:internal_encoding] = kwargs[:internal_encoding]
    end

    result[:internal_encoding] = nil if result[:internal_encoding] == '-'
    result[:newline] = kwargs[:newline] if kwargs.key?(:newline)

    result
  end

  def io_like_parse_mode_string(mode)
    result = {}

    mode = 'r' if mode.nil?
    mode, result[:external_encoding], result[:internal_encoding] =
      mode.split(':')

    case mode[0]
    when 'r', 'w', 'a'
      # Only check for a valid mode.
    else
      raise ArgumentError, "invalid access mode #{mode}"
    end

    mode[1, 2].each_char do |c|
      case c
      when '+'
        # Ignore this since it only has meaning for read/write-ablity.
      when 'b'
        result[:binmode] = true
      when 't'
        result[:binmode] = false
      else
        raise ArgumentError, "invalid access mode #{mode}"
      end
    end

    result
  end

  def io_like_wrapped_io(io, *args, **kwargs, &block)
    settings = io_like_parse_io_settings(*args, **kwargs)
    settings[:sync] = io.sync
    settings[:autoclose] = kwargs.fetch(:autoclose, true)
    IO::Like.open(
      IO::LikeHelpers::BufferedIO.new(
        IO::LikeHelpers::IOWrapper.new(io), autoclose: settings[:autoclose]
      ),
      **settings,
      &block
    )
  end

  # Replace mspec's new_io helper method to return an IO::Like wrapped IO.
  alias_method :__mspec_new_io, :new_io
  def new_io(name, mode = 'w:utf-8')
    if Hash === mode # Avoid kwargs warnings on Ruby 2.7+
      io_like_wrapped_io(__mspec_new_io(name, mode), **mode)
    else
      io_like_wrapped_io(__mspec_new_io(name, mode), mode)
    end
  end

  # Replace the Kernel.open method to return an IO::Like wrapped IO.
  alias_method :__open, :open
  def open(*args, &block)
    return __open(*args, &block) if caller.grep(%r{_spec\.rb:\d+:in }).empty?
    io_like_wrapped_io(__open(*args), *args[1..-1], &block)
  end
end

class File
  # Replace File.open to use/provide an IO::Like wrapped File.
  class << self
    alias_method :__file_open, :open
    def open(*args, **kwargs, &block)
      if caller.grep(%r{_spec\.rb:\d+:in }).empty?
        return __file_open(*args, **kwargs, &block)
      end

      io_like_wrapped_io(
        __file_open(*args, **kwargs),
        *args[1..-1],
        **kwargs,
        &block
      )
    end
  end
end

class IO
  # Replace IO.pipe to use/provide IO::Like wrapped endpoints.
  class << self
    alias_method :__pipe, :pipe
    def pipe(*args, &block)
      return __pipe(*args, &block) if caller.grep(%r{_spec\.rb:\d+:in }).empty?

      r, w = __pipe(*args)
      r, w = io_like_wrapped_io(r), io_like_wrapped_io(w)

      return r, w unless block_given?

      begin
        yield(r, w)
      ensure
        r.close
        w.close
      end
    end

    # Implement simplified IO.popen replacement that returns a duplexed IO::Like
    # instance wrapping read and write pipes.
    alias_method :__popen, :popen
    def popen(cmd, mode, &block)
      if caller.grep(%r{_spec\.rb:\d+:in }).empty?
        return __popen(cmd, mode, &block)
      end

      read = false
      write = false
      case mode[0]
      when 'r'
        read = true
      when 'w'
        write = true
      end
      if mode[1] == '+'
        read = true
        write = true
      end

      r_parent = w_parent = r_child = w_child = nil
      kwargs = {}
      if read
        r_parent, w_child = __pipe
        kwargs[:out] = w_child
      end
      if write
        r_child, w_parent = __pipe
        kwargs[:in] = r_child
      end

      pid = Process.spawn(cmd, **kwargs)
      Process.detach(pid)

      r_child.close unless r_child.nil?
      w_child.close unless w_child.nil?
      unless r_parent.nil?
        r_parent =
          IO::LikeHelpers::BufferedIO.new(
            IO::LikeHelpers::IOWrapper.new(r_parent)
          )
      end
      unless w_parent.nil?
        w_parent =
          IO::LikeHelpers::BufferedIO.new(
            IO::LikeHelpers::IOWrapper.new(w_parent)
          )
      end

      IO::Like.open(r_parent, w_parent, pid: pid, &block)
    end
  end
end

# Remap stdout and stderr to be IO::Like wrappers (as used in some tests).
unless IO::Like === $stdout
  $stdout = io_like_wrapped_io($stdout, autoclose: false)
  $stderr = io_like_wrapped_io($stderr, autoclose: false)
end
