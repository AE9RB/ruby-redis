require File.join(File.dirname(__FILE__), '../lib/redis')
require 'hiredis/reader'
require 'benchmark'

def runit qty, data
  success = 0
  redis = Redis.connect '127.0.0.1', 6379
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
        end
      end
    end
  end
  redis.attach Cool.io::Loop.default
  Cool.io::Loop.default.run
  raise 'fail' unless success == qty
end

data64k = 'XYZ!'*16384
data1m = data64k*16

Benchmark.bmbm do |bm|

  bm.report("75000  20b")  {
    runit 75000, 'xyzzy'*4
  }
  
  bm.report("10000  64k")  {
    runit 10000, data64k
  }

  bm.report("  250   1m")  {
    runit 250, data1m
  }

end
