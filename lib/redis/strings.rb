class Redis
  
  module Strings
  
    # Note: Redis does not have a dedicated integer type.
    # Integer operations will convert values to integers.
    
    def redis_GET key
      send_redis @database[key]
    end
    
    def redis_SET key, value
      @database[key] = value
      send_data "+OK\r\n"
    end
    
    def redis_MSET *args
      @database.merge! Hash[*args]
      send_data "+OK\r\n"
    end
    
    def redis_INCR key
      send_redis @database[key] = (@database[key] || 0).to_i + 1
    end
      
  end
end

if __FILE__ == $0
require_relative 'test'

end
