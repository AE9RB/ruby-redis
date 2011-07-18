require File.expand_path '../redis', File.dirname(__FILE__)
require 'fiber'

class Redis
  
  class FiberSync
    
    attr_accessor :timeout

    def initialize redis
      @redis = redis
      @timeout = nil
    end
    
    def sync
      self
    end
    
    def method_missing method, *args, &block
      result = @redis.send method, *args, &block
      if result.respond_to? :callback and result.respond_to? :errback
        result.timeout @timeout if @timeout and result.respond_to? :timeout
        result = Redis.sync result
        raise result if Exception === result
      end
      result
    end
  end
  
  def self.fiber connection
    fiber = Fiber.new do
      yield connection
    end.resume
  end
  
  def self.sync deferrable
    fiber = Fiber.current
    resumer = Proc.new do |relay|
      if fiber == Fiber.current
        return relay
      else
        fiber.resume relay
      end
    end
    deferrable.callback &resumer
    deferrable.errback &resumer
    Fiber.yield
  end
  
  def sync
    @fiber_synchronizer ||= FiberSync.new self
  end

end
