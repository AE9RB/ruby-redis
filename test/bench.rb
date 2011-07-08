require File.join(File.dirname(__FILE__), '../lib/redis')
require 'em-redis'
require 'benchmark'

def runit use_rr, qty, data
  
  thread = Thread.current
  success = 0
  Thread.new do
    EM.run do
      if use_rr
        redis = EventMachine.connect '127.0.0.1', 6379, Redis
      else
        redis = EM::Protocols::Redis.connect
      end
      redis.set "a", data do |response|
        qty.times do
          redis.get "a" do |response|
            success += 1
            if success >= qty
              thread.wakeup
              EM.stop
            end
          end
        end
      end
    end
  end
  sleep
  
end

Benchmark.bmbm do |bm|

  data8k = 'ABCD'*2048
  data64k = 'XYZ!'*16384
  data1m = data64k*16
  
  bm.report("em-redis   75000  20b")  {
    runit false, 75000, 'xyzzy'*4
  }

  bm.report("ruby-redis 75000  20b")  {
    runit true, 75000, 'xyzzy'*4
  }

  bm.report("em-redis   20000   8k")  {
    runit false, 20000, data8k
  }

  bm.report("ruby-redis 20000   8k")  {
    runit true, 20000, data8k
  }

  bm.report("em-redis   10000  64k")  {
    runit false, 10000, data64k
  }

  bm.report("ruby-redis 10000  64k")  {
    runit true, 10000, data64k
  }

  bm.report("em-redis   250     1m")  {
    runit false, 250, data1m
  }

  bm.report("ruby-redis 250     1m")  {
    runit true, 250, data1m
  }

end