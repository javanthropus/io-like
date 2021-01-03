require 'simplecov'
SimpleCov.start do
  add_filter %r{^/rubyspec/}
  add_filter %r{^/mspec/}
  add_filter %r{^/mspec-overrides/}
  add_filter %r{^/spec/}

  enable_coverage :branch

  command_name RUBY_DESCRIPTION
end

# Override default mspec file helpers to use IO::Like wrappers
require_relative 'mspec-overrides/helpers/io-like'
require_relative 'mspec-overrides/matchers/io_like_output_to_fd'
