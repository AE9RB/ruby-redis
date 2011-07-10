require File.join(File.dirname(__FILE__), '../lib/redis')
require 'em-hiredis'
require 'benchmark'

def runit kind, qty, data
  EventMachine.run do
    success = 0
    case kind
    when :ruby_redis
      redis = EventMachine.connect '127.0.0.1', 6379, Redis
    when :hiredis
      redis = EventMachine.connect '127.0.0.1', 6379, Redis, :hiredis => true
    when :em_hiredis
      # redis = EM::Hiredis::Client.connect
      redis = EM::Hiredis.connect
    end
    sleep 0.5 # lazy, give time to connect
    redis.set("a", data) do |status|
      qty.times do
        redis.get "a" do |response|
          if data.size == response.size
            success += 1
          else
            raise 'bad response'
          end
          if success == qty
            EM.defer {
              redis.close_connection
              EM.defer {
                EM.stop
              }
            }
          end
        end
      end
    end
  end
end

Benchmark.bmbm do |bm|

  data64k = 'XYZ!'*16384
  data1m = data64k*16
  
  bm.report("ruby-redis  75000  20b")  {
    runit :ruby_redis, 75000, 'xyzzy'*4
  }

  bm.report("  +hiredis  75000  20b")  {
    runit :hiredis, 75000, 'xyzzy'*4
  }

  bm.report("em-hiredis  75000  20b")  {
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