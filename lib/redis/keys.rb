class Redis
  module Keys
    
    def redis_RANDOMKEY
      return Response::NIL if @database.empty?
      @database.random_key
    end
  
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
      @database.expire key, seconds.to_redis_i
    end

    def redis_EXPIREAT key, timestamp
      @database.expire_at key, timestamp.to_redis_i
    end
    
    def redis_RENAME key, newkey
      raise 'key and newkey are identical' if key == newkey
      raise 'key not found' unless @database.has_key? key
      @database[newkey] = @database[key]
      @database.delete key
    end
    
    def redis_RENAMENX key, newkey
      return false if @database.has_key? newkey
      redis_RENAME key, newkey
      true
    end
    
    def redis_MOVE key, db
      raise unless @database.has_key? key
      Redis.databases[db.to_redis_i][key] = @database[key]
      @database.delete key
      true
    rescue
      false
    end
    
      
  end
end

if __FILE__ == $0
require_relative 'test'

end
