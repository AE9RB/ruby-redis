#!/usr/bin/env ruby
if __FILE__ == $0
  Dir.chdir File.expand_path '../../..', __FILE__
  exec 'tclsh8.5 tests/test_helper.tcl'
else
  require 'minitest/autorun'
  # ruby unit test helpers go here
end
