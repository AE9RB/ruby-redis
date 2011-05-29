class Redis
  
  module Lists
    
    def redis_RPUSH key, value
      (@database[key] ||= []).push(value).size
    end
    
    def redis_RPOP key
      (@database[key] || []).pop
    end
      
  end
end

if __FILE__ == $0
require_relative 'test'

end
