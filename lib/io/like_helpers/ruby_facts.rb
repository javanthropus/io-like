# frozen_string_literal: true

class IO; module LikeHelpers

##
# This module provides constants that represent true/false facts about the Ruby
# runtime.
module RubyFacts
  ##
  # Set to `true` if the runtime Ruby version is less than 3.4.
  RBVER_LT_3_4 = Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.4')

  ##
  # Set to `true` if the runtime Ruby version is less than 3.3.
  RBVER_LT_3_3 = Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.3')

  ##
  # Set to `true` if the runtime Ruby version is less than 3.2.
  RBVER_LT_3_2 = Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.2')

  ##
  # Set to `true` if the runtime Ruby version is less than 3.1.
  RBVER_LT_3_1 = Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.1')

  ##
  # Set to `true` if the runtime Ruby version is less than 3.0.4.
  RBVER_LT_3_0_4 = Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.0.4')

  ##
  # Set to `true` if the runtime Ruby version is less than 3.0.
  RBVER_LT_3_0 = Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.0')

  ##
  # Set to `true` if the platform is Windows.
  RBPLAT_IS_WINDOWS = RUBY_PLATFORM =~ /mswin|mingw/
end
end; end
