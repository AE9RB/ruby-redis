require 'eventmachine'
require 'thread'

# We need exceptions and assertions on the main thread for testing.
# This will not leak threads because EM.run only blocks the first time.

class BlockingRedis

  attr :timeout

  def initialize io
    @timeout = 1
    thread = Thread.current
    error = nil
    Thread.new do
      begin
        EventMachine.run do
          @redis = EventMachine::attach io, Redis
          thread.wakeup
        end
      rescue Exception => e
        error = e
        thread.wakeup
      end
    end
    sleep
    raise error if error
  end
  
  def method_missing method, *args, &block
    result = error = nil
    thread = Thread.current
    if @redis.respond_to? method
      result = @redis.send(method, *args, &block)
    else
      @redis.send(method, *args).callback{ |*msg|
        result = msg
        thread.wakeup
      }.errback{ |msg|
        error = msg
        thread.wakeup
      }.timeout @timeout
      sleep
    end
    raise error if error
    result
  end

  # Could be suitable for application use if commands are prototyped.
  # def hgetall key
  #   Hash[*method_missing(:hgetall, key)]
  # end
  
end

