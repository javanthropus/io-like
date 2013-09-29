require File.expand_path("../rubyspec/spec_helper",__FILE__)

# Override default mspec file helpers to use IO::Like wrappers
require File.expand_path("../mspec/helpers/io-like", __FILE__)
require File.expand_path("../mspec/matchers/io_like_output_to_fd", __FILE__)

# Remap stdout,stderr to be IO::Like wrappers (as used in some tests)
unless FileIOWrapper === $stdout
  $stdout = FileIOWrapper.new($stdout, 'w')
  $stdout.sync = true
  $stderr = FileIOWrapper.new($stderr, 'w')
  $stderr.sync = true
end
