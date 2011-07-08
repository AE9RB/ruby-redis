require 'eventmachine'
require 'thread'

class Redis::Client

  attr_accessor :timeout

  def initialize io
    @timeout = 1
    thread = Thread.current
    error = nil
    if EventMachine.reactor_running?
      @redis = EventMachine.attach io, Redis
    else
      # Send reactor elsewhere because we want exceptions
      # and assertions on the main thread for testing.
      Thread.new do
        begin
          EventMachine.run do
            @redis = EventMachine.attach io, Redis
            thread.wakeup
          end
        rescue Exception => e
          error = e
          thread.wakeup
        end
      end
      sleep
    end
    raise error if error
  end
  
  def method_missing method, *args, &block
    result = error = nil
    if @redis.respond_to? method
      result = @redis.send method, *args, &block
    else
      thread = Thread.current
      @redis.send(method, *args).callback{ |msg|
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
  
end

