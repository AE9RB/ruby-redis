class Redis
  
  # Note: Redis does not have a dedicated integer type.
  # Integer operations will convert values to integers.
  
  module Strings
  
    def redis_GET key
      @database[key]
    end
    
    def redis_MGET *keys
      keys.collect { |key| @database[key] }
    end
    
    def redis_SET key, value
      @database[key] = value
      Response::OK
    end
    
    def redis_MSET *args
      Hash[*args].each do |key, value|
        @database[key] = value
      end
      Response::OK
    end
    
    def redis_SETNX key, value
      if @database.has_key? key
        false 
      else
        @database[key] = value
        true
      end
    end
    
    def redis_INCR key
      @database[key] = (@database[key] || 0).to_redis_i + 1
    end

    def redis_INCRBY key, value
      @database[key] = (@database[key] || 0).to_redis_i + value.to_redis_i
    end

    def redis_DECRBY key, value
      @database[key] = (@database[key] || 0).to_redis_i - value.to_redis_i
    end
      
  end
end

if __FILE__ == $0
require_relative 'test'

end
