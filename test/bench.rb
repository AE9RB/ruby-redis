require File.join(File.dirname(__FILE__), '../lib/redis')
require 'em-hiredis'
require 'benchmark'

def runit kind, qty, data
  EventMachine.run do
    success = 0
    case kind
    when :ruby_redis
      redis = EventMachine.connect '127.0.0.1', 6379, Redis
    when :em_hiredis
      # redis = EM::Hiredis::Client.connect
      redis = EM::Hiredis.connect
    end
    # sleep 0.5 # lazy, give time to connect
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

data64k = 'XYZ!'*16384
data1m = data64k*16

[:ruby_redis, :hiredis].each do |type|
  
  Benchmark.bmbm do |bm|
  
    bm.report("%-10s 75000  20b"%type)  {
      runit :ruby_redis, 75000, 'xyzzy'*4
    }

    bm.report("%-10s  5000  64k"%type)  {
      runit :ruby_redis,  5000, data64k
    }
  
    bm.report("%-10s   250   1m"%type)  {
      runit :ruby_redis, 250, data1m
    }
    
  end

  puts
  
end