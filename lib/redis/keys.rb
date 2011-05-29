class Redis
  module Keys
  
    def redis_KEYS pattern
      @database.reduce([]) do |memo, key_val|
        key = key_val[0]
        memo.push key if File.fnmatch(pattern, key)
        memo
      end
    end
    
    def redis_DEL *keys
      count = 0
      keys.each do |key|
        count += 1  if @database.has_key? key
        @database.delete key
      end
      count
    end

    def redis_EXISTS key
      @database.has_key? key
    end
    
    def redis_EXPIRE key, seconds
      @database.expire key, seconds.to_i
    end

    def redis_EXPIREAT key, timestamp
      @database.expire_at key, timestamp.to_i
    end
      
  end
end

if __FILE__ == $0
require_relative 'test'

end
