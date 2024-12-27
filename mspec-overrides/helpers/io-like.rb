# encoding: UTF-8

$: << File.expand_path('../../../lib', __FILE__)

require 'mspec/helpers/io'
require 'mspec/matchers/output_to_fd'

require 'io/like'
require 'io/like_helpers/io_wrapper'

class Object
  def io_like_parse_io_settings(mode = nil, perm = nil, **kwargs)
    raise 'mode specified twice' if mode && kwargs[:mode]

    result = {}

    mode ||= kwargs[:mode]
    result.merge!(io_like_parse_mode_string(mode)) unless Integer === mode
    result.merge!(
      kwargs.select do |k, v|
        %i{encoding external_encoding internal_encoding}.include?(k)
      end
    )

    result[:encoding_opts] = kwargs.reject do |k, v|
      %i{mode flags encoding external_encoding internal_encoding textmode binmode autoclose}.include?(k)
    end

    result
  end

  def io_like_parse_mode_string(mode)
    result = {}

    mode = 'r' if mode.nil?
    mode, encoding = mode.split(':', 2)
    result[:encoding] = encoding if encoding && ! encoding.empty?

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
    settings[:binmode] = settings[:binmode] || kwargs.fetch(:binmode, false)
    IO::Like.open(
      IO::LikeHelpers::IOWrapper.new(io),
      **settings,
      &block
    )
  end

  def __called_by_rubyspec?
    caller.any? %r{rubyspec/core/io/.*_spec\.rb:\d+:in }
  end

  # Replace mspec's new_io helper method to return an IO::Like wrapped IO.
  alias_method :__mspec_new_io, :new_io
  def new_io(name, mode = 'w:utf-8')
    return __mspec_new_io(name, mode) unless __called_by_rubyspec?

    if Hash === mode # Avoid kwargs warnings on Ruby 2.7+
      io_like_wrapped_io(__mspec_new_io(name, mode), **mode)
    else
      io_like_wrapped_io(__mspec_new_io(name, mode), mode)
    end
  end

  # Replace the Kernel.open method to return an IO::Like wrapped IO.
  alias_method :__open, :open
  def open(*args, &block)
    return __open(*args, &block) unless __called_by_rubyspec?
    io_like_wrapped_io(__open(*args), *args[1..-1], &block)
  end
end

class File
  # Replace File.open to use/provide an IO::Like wrapped File.
  class << self
    alias_method :__file_open, :open
    def open(*args, **kwargs, &block)
      return __file_open(*args, **kwargs, &block) unless __called_by_rubyspec?

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
      return __pipe(*args, &block) unless __called_by_rubyspec?

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
    def popen(cmd, mode = 'r', &block)
      unless caller.any? %r{rubyspec/core/io/.*\.rb:\d+:in }
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

      args = []
      r_child.close unless r_child.nil?
      w_child.close unless w_child.nil?
      unless r_parent.nil?
        args << IO::LikeHelpers::IOWrapper.new(r_parent)
      end
      unless w_parent.nil?
        args << IO::LikeHelpers::IOWrapper.new(w_parent)
      end

      IO::Like.open(*args, pid: pid, sync: true, &block)
    end
  end
end
