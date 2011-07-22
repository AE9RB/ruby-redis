require 'fiber'
require File.expand_path 'client', File.dirname(__FILE__)

class Redis
  
  # Compatible with em-synchrony
  
  def self.synchrony blk=nil, tail=nil, &block
    blk ||= block
    context = Proc.new { Fiber.new { blk.call }.resume }
    EventMachine.run(context, tail)
  end

  class Synchrony
    def self.sync(df)
      f = Fiber.current
      xback = proc {|r|
        if f == Fiber.current
          return r
        else
          f.resume r
        end
      }
      df.callback &xback
      df.errback &xback
      Fiber.yield
    end
    def initialize redis
      @redis = redis
    end
    def method_missing method, *args, &block
      raise 'synchrony not allowed in multi' if @redis.in_multi? and method != :exec
      result = @redis.send method, *args, &block
      if result.respond_to? :callback and result.respond_to? :errback
        result = Synchrony.sync result
        raise result if Exception === result
      end
      result
    end
  end

  class Client

    def synchrony
      @synchrony ||= Synchrony.new self
    end
  
  end

end
