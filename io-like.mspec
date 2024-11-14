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
    # Cannot change object class from Ruby code, so we cannot comply with some
    # aspects of IO#reopen.
    /^IO#reopen changes the class of the instance to the class of the object returned by #to_io/,
    /^IO#reopen with an IO may change the class of the instance/,
    # This test checks too closely that the IO instance is actually an instance
    # of IO.
    /^IO#reopen with an IO does not call #to_io/,
    # This test runs in a subprocess where IO functions cannot be intercepted by
    # these tests.
    /^IO#reopen with a String affects exec\/system\/fork performed after it/,
    # There is currently no way to test that delegates are in append mode.
    /^IO#reopen with a String opens the file in append mode if the IO appends/,
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
    # This is too implementation specific to be worth emulating.
    /^IO#close does not call the #flush method but flushes the stream internally/,
    # This library does not replace the IO associated with STDOUT, so skip
    # methods related to it.
    /^IO#write on STDOUT/,
    # This test verifies buggy behavior on Ruby 3.1 and below that is not worth
    # supporting.
    /^IO#syswrite on a pipe raises Errno::E(AGAIN|WOULDBLOCK) when the write would block/,
    # These tests are too C implementation specific.
    /^IO#each_line with limit does not accept Integers that don't fit in a C off_t/,
    /^IO#each with limit does not accept Integers that don't fit in a C off_t/,
    /^IO#gets does not accept limit that doesn't fit in a C off_t/,
    /^IO#lineno= does not accept Integers that don't fit in a C int/,
    /^IO#readline when passed limit does not accept Integers that don't fit in a C off_t/,
    /^IO#readlines when passed limit does not accept Integers that don't fit in a C off_t/,
    # IO#ungetc and IO#ungetbyte should not affect the stream position.  Issue #20889.
    /^IO#ungetc adjusts the stream position/,
  ]

  # Exclude IO specs not relevant to IO::Like.
  set :xpatterns,
    constant_checks +
    irrelevant_class_methods +
    irrelevant_instance_methods +
    non_compliant
end

# vim: set ft=ruby:
