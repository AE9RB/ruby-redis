# -*- encoding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'lib/redis/version')
 
Gem::Specification.new do |s|
  s.name        = 'ruby-redis'
  s.version     = Redis::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['David Turnbull']
  s.email       = ['dturnbull@gmail.com']
  s.homepage    = 'https://github.com/dturnbull/ruby-redis'
  s.summary     = 'Ruby implementation of a Redis server and client'
  # s.description = ''
 
  s.required_rubygems_version = '>= 1.3.6'
  s.rubyforge_project         = 'ruby-redis'
 
  s.add_dependency 'eventmachine'
  s.add_development_dependency 'minitest'

  s.files        = Dir.glob('{bin,lib}/**/*') + %w(LICENSE README)
  s.executables  = ['ruby-redis']
  s.require_path = 'lib'
end