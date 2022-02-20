class IO; module LikeHelpers

##
# This module provides constants that represent true/false facts about the Ruby
# runtime.
module RubyFacts
  ##
  # Set to `true` if the runtime Ruby version is less than 3.1.
  RBVER_LT_3_1 = Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.1')

  ##
  # Set to `true` if the runtime Ruby version is less than 3.0.
  RBVER_LT_3_0 = Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.0')

  ##
  # Set to `true` if the runtime Ruby version is less than 2.7.
  RBVER_LT_2_7 = Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.7')
end
end; end
