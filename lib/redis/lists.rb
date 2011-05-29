class Redis
  
  module Lists
    
    def redis_RPUSH key, value
      send_redis (@database[key] ||= []).push(value).size
    end
    
    def redis_RPOP key
      send_redis (@database[key] || []).pop
    end
      
  end
end

if __FILE__ == $0
require_relative 'test'

end
