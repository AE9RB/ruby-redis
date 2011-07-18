require File.expand_path '../redis', File.dirname(__FILE__)

class Redis
  module Connection

    def redis_AUTH password
      raise 'invalid password' unless authorize password
      Response::OK
    end

    def redis_SELECT db_index
      database = Redis.databases[redis_i db_index]
      raise 'invalid DB index' unless database
      @database = database
      Response::OK
    end
    
    def redis_PING
      Response::PONG
    end

    def redis_ECHO str
      str
    end

    def redis_QUIT
      send_redis Response::OK
      raise CloseConnection
    end
    
  end
end