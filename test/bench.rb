require File.expand_path '../lib/redis', File.dirname(__FILE__)
require 'em-hiredis'
require 'benchmark'

def bench kind, qty, data
  success = 0
  EventMachine.run do
    redis = case kind
    when :ruby_redis then EventMachine.connect '127.0.0.1', 6379, Redis
    when :em_hiredis then EM::Hiredis.connect
    end
    redis.set("a", data) do
      qty.times do
        redis.get "a" do |response|
          if data.size == response.size
            success += 1
          else
            raise 'bad response'
          end
          if qty == success
            redis.close
            EM.stop
          end
        end
      end
    end
  end
  raise 'fail' unless success == qty
end

data64k = 'XYZ!'*16384
data1m = data64k*16

types = [:em_hiredis, :ruby_redis]
# types = [:ruby_redis, :em_hiredis]
# types = [:ruby_redis]
  
Benchmark.bmbm do |bm|

  types.each do |type|
    bm.report("%-10s 75000  20b"%type)  {
      bench type, 75000, 'xyzzy'*4
    }
  end

  types.each do |type|
    bm.report("%-10s  5000  64k"%type)  {
      bench type, 5000, data64k
    }
  end
  
  types.each do |type|
    bm.report("%-10s   250   1m"%type)  {
      bench type, 250, data1m
    }
  end
    
  
end