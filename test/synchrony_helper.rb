require_relative '../lib/redis/synchrony'

def synchrony
  error = nil
  Redis.synchrony do
    begin
      redis = EventMachine.connect '127.0.0.1', 6379, Redis
      yield redis, redis.synchrony
    rescue Exception => e
      error = e
    ensure
      redis.close_connection
      EventMachine.stop
    end
  end
  raise error if error
end
