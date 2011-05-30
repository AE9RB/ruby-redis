class Redis
  
  # Note: Redis does not have a dedicated integer type.
  # Integer operations will convert values to integers.
  
  module Strings
    
    def redis_GET key
      value = @database[key]
      raise 'key contains invalid value type' if value and !value.respond_to?(:to_s)
      value
    end
    
    def redis_SETRANGE key, offset, value
      data = (redis_GET(key)||'').to_s
      offset = offset.to_redis_i
      if data.size <= offset
        data += ' ' * (offset - data.size + value.size)
      end
      data[offset,value.size] = value
    end
    
    def redis_GETRANGE key, first, last
      redis_GET key[first.to_redis_i..last.to_redis_i]
    end
    
    def redis_GETBIT key, offset
      data = redis_GET key
      return 0 unless data
      data = data.to_s
      offset = offset.to_redis_i
      byte = offset / 8
      bit = 1 << offset % 8
      return 0 if data.size <= byte
      original_byte = data[byte].ord
      original_bit = original_byte & bit
      original_bit != 0
    end
    
    def redis_SETBIT key, offset, value
      data = (redis_GET(key)||'').to_s
      offset = offset.to_redis_i
      byte = offset / 8
      bit = 1 << offset % 8
      if data.size <= byte
        data += 0.chr * (byte - data.size + 1)
      end
      original_byte = data[byte].ord
      original_bit = original_byte & bit
      if value == '0'
        data[byte] = (original_byte & ~bit).chr
      elsif value == '1'
        data[byte] = (original_byte | bit).chr
      else
        raise 'bad value'
      end
      @database[key] = data
      original_bit != 0
    end
  
    def redis_STRLEN key
      value = redis_GET key
      value ? value.size : 0
    end

    def redis_MGET *keys
      keys.collect do |key|
        value = @database[key]
        (String === value) ? value : nil
      end
    end
    
    def redis_GETSET key, value
      old = redis_GET key
      @database[key] = value
      old
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
    
    def redis_MSETNX *args
      result = true
      Hash[*args].each do |key, value|
        result = false if @database.has_key? key
        @database[key] = value
      end
      result
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
