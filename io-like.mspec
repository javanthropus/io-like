# encoding: UTF-8

require_relative 'spec_helper'

class MSpecScript
  # An ordered list of the directories containing specs to run
  set :files, ['spec', 'rubyspec/core/io']

  # The default implementation to run the specs.
  set :target, 'ruby'

  # Ignore tests for constants.
  constant_checks = [/IO::SEEK_SET/, /IO::SEEK_CUR/, /IO::SEEK_END/]

  # Ignore IO class methods.
  irrelevant_class_methods = [
    /^IO\.binread/, /^IO\.binwrite/, /^IO\.copy_stream/, /^IO\.foreach/, /^IO\.for_fd/,
    /^IO\.new/, /^IO\.open/, /^IO\.pipe/, /^IO\.popen/, /^IO\.readlines/, /^IO\.read/,
    /^IO\.select/, /^IO\.sysopen/, /^IO\.try_convert/, /^IO\.write/
  ]

  # Ignore instance methods related to file descriptor IO.
  irrelevant_instance_methods = [
    /^IO#initialize/
  ]

  # Ignore some intentionally non-compliant methods.
  non_compliant = [
    # These are low level methods that cannot be emulated with the same
    # concurrency guarantees as real implementations.
    /^IO#pread/, /^IO#pwrite/,
    # Cannot change object class from Ruby code, so we cannot comply with some
    # aspects of IO#reopen.
    /^IO#reopen changes the class of the instance to the class of the object returned by #to_io/,
    /^IO#reopen with an IO may change the class of the instance/,
    # This test checks too closely that the io instance is actually an instance
    # of IO.
    /^IO#reopen with an IO does not call #to_io/,
    # IO::Like#to_io always returns the underlying IO instance if there is one
    # and raises errors otherwise, so it never returns self.
    /^IO#to_io returns self/,
    # Cannot set $_ from Ruby code, so we cannot comply with anything mentioning
    # $_.
    /\$_/,
    # Cannot set $? from Ruby code, so we cannot comply with anything depending
    # on $?.
    /^IO#close on an IO\.popen stream sets \$?/,
    /^IO#close on an IO\.popen stream waits for the child to exit/,
    # Invalid test.  See https://github.com/ruby/spec/pull/960.
    /^IO#read in binary mode does not transcode file contents when an internal encoding is specified$/,
  ]

  # Exclude IO specs not relevant to IO::Like.
  set :xpatterns,
    constant_checks +
    irrelevant_class_methods +
    irrelevant_instance_methods +
    non_compliant
end

# vim: set ft=ruby:
