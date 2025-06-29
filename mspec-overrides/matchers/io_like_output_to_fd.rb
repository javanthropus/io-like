require 'mspec/helpers/tmp'

# Lower-level output speccing mechanism for a single
# output stream. Unlike OutputMatcher which provides
# methods to capture the output, we actually replace
# the FD itself so that there is no reliance on a
# certain method being used.
#
# This is the IO::Like version which understands that stdout and stderr are
# actually FileIOWrappers
class IOLikeOutputToFDMatcher
  def initialize(expected, to)
    @to, @expected = to, expected

    case @to
    when STDOUT, $stdout
      @to_name = "STDOUT"
    when STDERR, $stderr
      @to_name = "STDERR"
    when IO, IO::Like
      @to_name = @to.object_id.to_s
    else
      raise ArgumentError, "#{@to.inspect} is not a supported output target"
    end
  end

  def with_tmp
    path = tmp("mspec_output_to_#{$$}_#{Time.now.to_i}")
    File.__file_open(path, 'w+') { |io|
      yield(io)
    }
  ensure
    File.delete path if path
  end

  def matches?(block)
    old_to = @to.to_io.dup
    with_tmp do |out|
      # Replacing with a file handle so that Readline etc. work
      @to.to_io.reopen out
      begin
        block.call
      ensure
        @to.flush
        @to.to_io.reopen old_to
        old_to.close
      end

      out.rewind
      @actual = out.read

      case @expected
      when Regexp
        !(@actual =~ @expected).nil?
      else
        @actual == @expected
      end
    end
  end

  def failure_message()
    ["Expected (#{@to_name}): #{@expected.inspect}\n",
     "#{'but got'.rjust(@to_name.length + 10)}: #{@actual.inspect}\nBacktrace"]
  end

  def negative_failure_message()
    ["Expected output (#{@to_name}) to NOT be:\n", @actual.inspect]
  end
end

module MSpecMatchers
  private def output_to_fd(what, where = STDOUT)
    IOLikeOutputToFDMatcher.new what, where
  end
end
