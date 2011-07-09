require File.join(File.dirname(__FILE__), '../redis')
require 'fiber'

class Redis
  
  # This is compatible with em-synchrony
  
  def self.synchrony blk=nil, tail=nil, &block
    blk ||= block
    context = Proc.new { Fiber.new { blk.call }.resume }
    EventMachine.run(context, tail)
  end
  
  class Synchrony
    
    attr_accessor :timeout

    def initialize redis
      @redis = redis
      @timeout = nil
    end
    
    def method_missing method, *args, &block
      result = @redis.send method, *args, &block
      if result.respond_to? :callback and result.respond_to? :errback
        f = Fiber.current
        xback = proc {|r|
          if f == Fiber.current
            return r
          else
            f.resume r
          end
        }
        result.callback &xback
        result.errback &xback
        result.timeout @timeout if @timeout
        result = Fiber.yield
        raise result if Exception === result
      end
      result
    end
  end
  
  def synchrony
    Synchrony.new self
  end

end
