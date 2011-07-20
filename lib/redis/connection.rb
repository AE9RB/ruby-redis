class Redis
  module Connection
    
    def redis_AUTH password
      raise 'invalid password' unless authorized password
      :'+OK'
    end

    def redis_SELECT db_index
      database = Redis.databases[redis_i db_index]
      raise 'invalid DB index' unless database
      @database = database
      :'+OK'
    end
    
    def redis_PING
      :'+PONG'
    end

    def redis_ECHO str
      str
    end

    def redis_QUIT
      send_redis :'+OK'
      :quit
    end
    
  end
end