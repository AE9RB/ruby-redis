require 'set'

module Redis
  module Sets
  
    def redis_SADD key, member
      record = (@database[key] ||= Set.new)
      redis_t Set, record
      return false if record.include? member
      record.add member
      true
    end
    
    def redis_SREM key, member
      record = @database[key] || []
      return false unless record.include? member
      record.delete member
      @database.delete key if record.empty?
      return true
    end
    
    # Type checks are only to make tests pass
    def redis_SMOVE source, destination, member
      source_record = @database[source] || Set.new
      dest_record = @database[destination]
      redis_t Set, source_record
      redis_t NilClass, Set, dest_record
      return false unless source_record.include? member
      (@database[destination] ||= Set.new).add member
      source_record.delete member
      @database.delete source if source_record.empty?
      return true
    end
      
    def redis_SCARD key
      (@database[key] || []).size
    end
    
    def redis_SISMEMBER key, member
      (@database[key] || []).include? member
    end
    
    def redis_SMEMBERS key
      (@database[key] || []).to_a
    end
    
    def redis_SINTER *keys
      keys.each { |key| redis_t NilClass, Array, Set, @database[key] }
      keys.reduce(nil) do |memo, key| 
        memo ? memo & (@database[key]||[]) : (@database[key]||Set.new) 
      end
    end
    
    def redis_SINTERSTORE destination, *keys
      record = redis_SINTER *keys
      if record.empty?
        @database.delete destination 
      else
        @database[destination] = record
      end
      record.size
    end

    def redis_SUNION *keys
      keys.each { |key| redis_t NilClass, Array, Set, @database[key] }
      keys.reduce(Set.new) { |memo, key| memo | (@database[key]||[]) }
    end

    def redis_SUNIONSTORE destination, *keys
      record = redis_SUNION *keys
      if record.empty?
        @database.delete destination 
      else
        @database[destination] = record
      end
      record.size
    end
    
    def redis_SDIFF *keys
      keys.reduce(nil) { |memo, key| memo ? memo - (@database[key]||[]) : (@database[key]||Set.new) }
    end
    
    def redis_SDIFFSTORE destination, *keys
      (@database[destination] = redis_SDIFF *keys).size
    end
    
    def redis_SPOP key
      set = @database[key]
      return nil unless set
      rec = rand set.size
      result = set.to_a[rec]
      set.delete result
      @database.delete key if set.empty?
      result
    end
    
    def redis_SRANDMEMBER key
      set = (@database[key] || [])
      return nil if set.empty?
      set.to_a[rand set.size]
    end
    
  end
end
