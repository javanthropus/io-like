# Explicitly loading rubygems is necessary to satisfy one of the StringIO tests
# that uses the assert_separately method to run an instance of Ruby with
# rubygems explicitly disabled.
require 'rubygems'

# Load up the LikeStringIO implementation and masquerade it as StringIO.
require_relative '../likestringio'
StringIO = LikeStringIO
