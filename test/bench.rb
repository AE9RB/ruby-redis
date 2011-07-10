require File.join(File.dirname(__FILE__), '../lib/redis')
require 'em-synchrony' # >= 0.3
require 'em-synchrony/em-hiredis'
require 'benchmark'

# I couldn't get em-redis stable enough to include here, but
# it was slower on every test, 20-30X slower on 1gig strings.

def runit kind, qty, data
  EventMachine.synchrony do
    success = 0
    case kind
    when :ruby_redis
      redis = EventMachine.connect '127.0.0.1', 6379, Redis
    when :hiredis
      redis = EventMachine.connect '127.0.0.1', 6379, Redis, :hiredis => true
    when :em_hiredis
      # redis = EventMachine.connect '127.0.0.1', 6379, Redis
      redis = EM::Hiredis::Client.connect
    end
    redis.set("a", data)
    size = data.size
    qty.times do
      redis.get "a" do |response|
        if size == response.size
          success += 1
        else
          raise 'bad response'
        end
        if success == qty
          redis.close_connection
          EM.defer {EM.stop}
        end
      end
    end
  end
end

Benchmark.bmbm do |bm|

  data64k = 'XYZ!'*16384
  data1m = data64k*16

  bm.report("ruby-redis  75000  10b")  {
    runit :ruby_redis, 75000, 'xyzzy'*4
  }

  bm.report("  +hiredis  75000  10b")  {
    runit :hiredis, 75000, 'xyzzy'*4
  }
  
  bm.report("em-hiredis  75000  10b")  {
    runit :em_hiredis, 75000, 'xyzzy'*4
  }
  
  bm.report("ruby-redis  10000  64k")  {
    runit :ruby_redis, 10000, data64k
  }
  
  bm.report("  +hiredis  10000  64k")  {
    runit :hiredis, 10000, data64k
  }
  
  bm.report("em-hiredis  10000  64k")  {
    runit :em_hiredis, 10000, data64k
  }
  
  bm.report("ruby-redis    250   1m")  {
    runit :ruby_redis, 250, data1m
  }

  bm.report("  +hiredis    250   1m")  {
    runit :hiredis, 250, data1m
  }

  bm.report("em-hiredis    250   1m")  {
    runit :em_hiredis, 250, data1m
  }
  
end