class Redis
  
  module Strings
  
    # Note: Redis does not have a dedicated integer type.
    # Integer operations will convert values to integers
    # so further calls will be faster.
    
    def redis_GET key
      send_redis @database[key.to_s]
    end
    
    def redis_SET key, value
      @database[key.to_s] = value
      send_data "+OK\r\n"
    end
    
    def redis_MSET *args
      #TODO keys to_s
      @database.merge! Hash[*args]
      send_data "+OK\r\n"
    end
    
    def redis_INCR key
      key = key.to_s
      value = (@database[key] || 0).to_i + 1
      @database[key] = value
      send_redis value
    end
      
  end
end

if __FILE__ == $0
require_relative 'test'

end
