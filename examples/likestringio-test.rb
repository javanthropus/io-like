if ARGV.size < 1
  $stderr.puts "#{File.basename($0)}: path to ruby sources not provided"
  exit 1
end

if %w(-h --help).include?(ARGV[0])
  puts <<-USAGE
Usage: #{File.basename($0)} RUBY_SOURCE ...

Arguments:
RUBY_SOURCE         the path to a checkout of the Ruby source code
...                 arguments passed to the StringIO test script

This script runs the StringIO tests provided by the Ruby source code using the
LikeStringIO example class to replace StringIO.
  USAGE
  exit
end
ruby_dir = ARGV.shift

# This adds the test/unit libraries and others to the load path for use by the
# StringIO tests included with the ruby sources.
ruby_tool_lib = File.join(ruby_dir, 'tool/lib')
$:.unshift(ruby_tool_lib)

# This tricks the StringIO tests to run against LikeStringIO by adding an
# override for stringio.rb to the load path that makes LikeStringIO take the
# place of StringIO.  
stringio_override = File.join(File.dirname(File.expand_path(__FILE__)), 'likestringio-test')
$:.unshift(stringio_override)

# Run the StringIO tests.  Note that any remaining command line arguments are
# passed along verbatim.
require File.join(ruby_dir, 'test/stringio/test_stringio')
