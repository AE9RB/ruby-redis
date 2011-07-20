class Redis
  module Hashes
    
    def redis_HSET key, field, value
      hash = @database[key] ||= {}
      result = !hash.has_key?(field)
      hash[field] = value
      result
    end
    
    def redis_HEXISTS key, field
      (@database[key] || {}).has_key? field
    end

    def redis_HSETNX key, field, value
      hash = @database[key] || {}
      return false if hash.has_key? field
      redis_HSET key, field, value
      return true
    end
    
    def redis_HKEYS key
      (@database[key] || {}).keys
    end
    
    def redis_HVALS key
      (@database[key] || {}).values
    end
    
    def redis_HMSET key, *args
      (@database[key] ||= {}).merge! Hash[*args]
      :'+OK'
    end
      
    def redis_HMGET key, *fields
      hash = (@database[key] || {})
      redis_t Hash, hash
      fields.collect do |field|
        hash[field]
      end
    end
      
    def redis_HLEN key
      (@database[key] || {}).size
    end

    def redis_HGET key, field
      (@database[key] || {})[field]
    end
    
    def redis_HGETALL key
      @database[key] || {}
    end

    def redis_HDEL key, field
      hash = @database[key] || {}
      result = hash.has_key? field
      hash.delete field
      result
    end
    
    def redis_HINCRBY key, field, increment
      hash = @database[key] ||= {}
      value = redis_i(hash[field] ||= 0)
      value += redis_i increment
      hash[field] = value
    end
    
  end
end
