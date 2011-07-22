class Redis
  class Database
    
    class Watcher

      attr_reader :bound

      def initialize
        @watched = []
        @bound = true
      end

      def bind database, *keys
        return unless @bound
        keys.each do |key|
          entry = [database, key]
          next if @watched.include? entry
          @watched << entry
          (database.watchers[key] ||= []).push self
        end
      end

      def unbind
        return unless @bound
        @watched.each do |database, key|
          key_df_list = database.watchers[key]
          next unless key_df_list
          key_df_list.delete_if { |e| e == self }
        end
        @bound = false
      end

    end
    
    # Redis databases are volatile dictionaries.
    
    attr_reader :blocked_pops, :watchers
    
    def initialize
      @dict = {}
      @expiry = {}
      @blocked_pops = {}
      @watchers = {}
    end
    
    def touch key
      (@watchers[key]||[]).each do |watcher|
        watcher.unbind
      end
    end
    
    def expire key, seconds
      return false unless @dict.has_key? key
      touch key
      @expiry[key] = Time.now + seconds
      return true
    end

    def expire_at key, unixtime
      return false unless @dict.has_key? key
      touch key
      @expiry[key] = Time.at unixtime
      return true
    end
    
    def ttl key
      check_expiry key
      time = @expiry[key]
      return -1 unless time
      (time - Time.now).round
    end
    
    def persist key
      result = @expiry.has_key? key
      touch key if result
      @expiry.delete key
      result
    end
    
    def random_key
      @dict.keys[rand @dict.size]
    end
    
    def [] key
      check_expiry key
      @dict[key]
    end

    def []= key, value
      touch key
      @expiry.delete key
      @dict[key] = value
    end
    
    def has_key? key
      check_expiry key
      @dict.has_key? key
    end
    
    def delete key
      touch key
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
      # We don't trigger watchers of unset records
      @dict.each_key { |key| touch key }
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
