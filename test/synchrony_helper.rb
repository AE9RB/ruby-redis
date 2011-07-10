def synchrony
  Redis.synchrony do
    redis = EventMachine.connect '127.0.0.1', 6379, Redis
    yield redis, redis.synchrony
    redis.close_connection
    EventMachine.stop
  end
end
