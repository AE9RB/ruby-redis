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
    when :em_hiredis
      redis = EM::Hiredis::Client.connect
    end
    redis.set("a", data)
    qty.times do
      redis.get "a" do |response|
        success += 1
        if success == qty
          redis.close_connection
          EM.stop 
        end
      end
    end
  end

  return

end

Benchmark.bmbm do |bm|

  data64k = 'XYZ!'*16384
  data1m = data64k*16

  bm.report("ruby-redis 75000  10b")  {
    runit :ruby_redis, 75000, 'xyzzy'*2
  }
  
  bm.report("em-hiredis 75000  10b")  {
    runit :em_hiredis, 75000, 'xyzzy'*2
  }
  
  bm.report("ruby-redis 10000  64k")  {
    runit :ruby_redis, 10000, data64k
  }
  
  bm.report("em-hiredis 10000  64k")  {
    runit :em_hiredis, 10000, data64k
  }
  
  bm.report("ruby-redis   250   1m")  {
    runit :ruby_redis, 250, data1m
  }

  bm.report("em-hiredis   250   1m")  {
    runit :em_hiredis, 250, data1m
  }
  
end