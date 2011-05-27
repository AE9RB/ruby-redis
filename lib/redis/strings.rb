class Redis
  module Strings
  
    # Note: Redis does not have a dedicated integer type.
    # Integer operations will convert values to integers
    # so further calls will be faster.
    
    def redis_GET key
      value = @database[key]
      if value==nil
        send_data "$-1\r\n"
      else
        send_data "$#{value.size}\r\n#{value}\r\n"
      end
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
      value = (@database[key].to_i || 0) + 1
      @database[key] = value
      send_data ":#{value}\r\n"
    end
      
  end
end

if __FILE__ == $0
require_relative 'test'

end
