require File.expand_path '../redis', File.dirname(__FILE__)
require 'fiber'

class Redis
  
  # Compatible with em-synchrony
  # Not included by default, use:
  #   require 'redis/synchrony'
  
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
    
    attr_accessor :timeout

    def initialize redis
      @redis = redis
      @timeout = nil
    end
    
    def pubsub_callback
      raise 'only available async'
    end
    
    def method_missing method, *args, &block
      result = @redis.send method, *args, &block
      if result.respond_to? :callback and result.respond_to? :errback
        result.timeout @timeout if @timeout and result.respond_to? :timeout
        result = self.class.sync result
        raise result if Exception === result
      end
      result
    end
  end
  
  class Command
    # Provide a nice message when attempting sync inside multi_exec
    def synchrony
      raise 'synchrony unavilable here'
    end
  end
  
  def self.synchrony blk=nil, tail=nil, &block
    blk ||= block
    context = Proc.new { Fiber.new { blk.call }.resume }
    EventMachine.run(context, tail)
  end
  
  def synchrony
    @synchrony ||= Synchrony.new self
  end

end
