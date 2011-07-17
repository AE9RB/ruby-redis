require_relative '../lib/redis/synchrony'

def synchrony &block
  error = nil
  Redis.synchrony do
    begin
      redis = nil
      EventMachine.connect('127.0.0.1', 6379, Redis) do |connection|
        redis = connection
      end
      yield redis, redis.synchrony
    rescue Exception => e
      error = e
    ensure
      redis.close_connection
    end
  end
  raise error if error
end
