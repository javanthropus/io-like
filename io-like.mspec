# encoding: UTF-8

require 'mspec/runner/formatters'

class MSpecScript
  # An ordered list of the directories containing specs to run
  set :files, ['spec', 'rubyspec']

  # The default implementation to run the specs.
  set :target, 'ruby'

  irrelevant_class_methods = [
    "IO.for_fd", "IO.foreach", "IO.pipe", "IO.popen",
    "IO.read", "IO.new", "IO#initialize", "IO.open", "IO::SEEK", "IO.select",
    # rubyspec bug - this is actually IO.readlines, not IO#readines
    "IO#readlines when passed a string that starts with a |"
  ]

  # Also instance methods related to file descriptor IO
  irrelevant_instance_methods = [
    "IO#dup", "IO#ioctl", "IO#fcntl", "IO#fsync", "IO#pid", "IO#stat",
    "IO#fileno", "IO#to_i", "IO#reopen", "terminal device (TTY)"
  ]

  # and some intentionally not compliant
  non_compliant = [
    "IO#read_nonblock changes the behavior of #read to nonblocking",
    "IO#ungetc raises IOError when invoked on stream that was not yet read",
    # The very definition says to expect unpredictable results for the below.
    "IO#sysread on a file reads normally even when called immediately after a buffered IO#read",
    # Cannot set $_ from Ruby code, so we cannot comply with anything mentioning
    # $_.
    "$_"
  ]

  # Exclude IO specs not relevant to IO::Like.
  set :excludes, irrelevant_class_methods + irrelevant_instance_methods + non_compliant
end
