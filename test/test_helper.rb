require File.join(File.dirname(__FILE__), '../lib/redis')
require 'minitest/unit'
require 'minitest/spec'

# helpers
Dir.glob(File.expand_path('**/*_helper.rb', File.dirname(__FILE__))).each {|f| require f}

# run all
if $0 == __FILE__
  Dir.glob(File.expand_path('**/*_test.rb', File.dirname(__FILE__))).each {|f| require f}
end

# From 'minitest/autorun', added sync reactor
at_exit {
  next if $! # don't run if there was an exception

  # the order here is important. The at_exit handler must be
  # installed before anyone else gets a chance to install their
  # own, that way we can be assured that our exit will be last
  # to run (at_exit stacks).
  exit_code = nil

  at_exit { exit false if exit_code && exit_code != 0 }
  exit_code = nil
  Redis.synchrony do
    exit_code = MiniTest::Unit.new.run ARGV
    EventMachine.stop
  end
  exit_code
} unless $installed_at_exit_test
$installed_at_exit_test = true