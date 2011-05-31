class Redis
  class Database
    
    # Redis databases are volatile dictionaries.
    
    # Used by lists to defer blocking pops
    attr_reader :lists_df
    
    def initialize
      @dict = {}
      @expiry = {}
      @lists_df = {}
    end
    
    def expire key, seconds
      return false unless @dict.has_key? key
      @expiry[key] = Time.now + seconds
      return true
    end

    def expire_at key, unixtime
      return false unless @dict.has_key? key
      @expiry[key] = unixtime
      return true
    end
    
    def random_key
      @dict.keys[rand @dict.size]
    end
    
    def [] key
      check_expiry key
      @dict[key]
    end

    def []= key, value
      @expiry.delete key
      @dict[key] = value
    end
    
    def has_key? key
      check_expiry key
      @dict.has_key? key
    end
    
    def delete key
      @dict.delete key
      @expiry.delete key
    end
    
    def reduce *args, &block
      @dict.reduce *args, &block
    end
    
    def size
      @dict.size
    end
    
    def clear
      @dict.clear
      @expiry.clear
    end
    
    def empty?
      @dict.empty?
    end
    
    private
    
    def check_expiry key
      expires_at = @expiry[key]
      delete key if expires_at and Time.now > expires_at
    end
    
  end
end