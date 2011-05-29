class Redis
  
  # Note: Redis does not have a dedicated integer type.
  # Integer operations will convert values to integers.
  
  module Strings
  
    def redis_GET key
      send_redis @database[key]
    end
    
    def redis_MGET *keys
      send_redis keys.collect { |key| @database[key] }
    end
    
    def redis_SET key, value
      @database[key] = value
      send_data "+OK\r\n"
    end
    
    def redis_MSET *args
      @database.merge! Hash[*args]
      send_data "+OK\r\n"
    end
    
    def redis_SETNX key, value
      return send_redis 0 if @database.has_key? key
      @database[key] = value
      send_redis 1
    end
    
    def redis_INCR key
      send_redis @database[key] = (@database[key] || 0).to_redis_i + 1
    end

    def redis_INCRBY key, value
      send_redis @database[key] = (@database[key] || 0).to_redis_i + value.to_redis_i
    end

    def redis_DECRBY key, value
      send_redis @database[key] = (@database[key] || 0).to_redis_i - value.to_redis_i
    end
      
  end
end

if __FILE__ == $0
require_relative 'test'

end
