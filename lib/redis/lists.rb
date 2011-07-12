require_relative '../redis'
require 'eventmachine'

class Redis
  
  module Lists
    
    class DeferredPop
      include EventMachine::Deferrable
      
      attr_reader :bound
      
      def initialize database, timeout_secs, *keys
        @database = database
        @keys = keys
        timeout timeout_secs if timeout_secs > 0
        errback { unbind }
        callback { unbind }
        keys.each do |key|
          (@database.blocked_pops[key] ||= []).push self
        end
        @bound = true
      end
      
      def unbind
        return unless @bound
        @keys.each do |key|
          key_df_list = @database.blocked_pops[key]
          next unless key_df_list
          key_df_list.delete_if { |e| e == self }
        end
        @bound = false
      end
      
    end
    
    def redis_LRANGE key, first, last
      first = redis_i first
      last = redis_i last
      list = @database[key] || []
      first = 0 if first < -list.size
      list[first..last]
    end
    
    def redis_LTRIM key, start, stop
      @database[key] = redis_LRANGE key, start, stop
    end
    
    def redis_BRPOP *args
      timeout = redis_pos_i args.pop
      args.each do |key|
        list = @database[key]
        if list and list.size > 0
          value = list.pop
          @database.delete key if list.empty?
          return [key, value]
        end
      end
      df = DeferredPop.new(@database, timeout, *args)
      df.errback { send_redis Response::NIL_MB }
      df.callback { |key, value| send_redis [key, value] }
      df
    end
    
    def redis_BLPOP *args
      timeout = redis_pos_i args.pop
      args.each do |key|
        list = @database[key]
        if list and list.size > 0
          value = list.shift
          @database.delete key if list.empty?
          return [key, value]
        end
      end
      df = DeferredPop.new(@database, timeout, *args)
      df.errback { send_redis Response::NIL_MB }
      df.callback { |key, value| send_redis [key, value] }
      df
    end

    def redis_RPOPLPUSH source, destination
      source_list = @database[source]
      return nil unless source_list
      redis_t Array, source_list
      redis_t NilClass, Array, @database[destination]
      value = source_list.pop
      @database.delete source if source_list.empty?
      redis_LPUSH destination, value
      return value
    end
    
    def redis_BRPOPLPUSH source, destination, timeout
      source_list = @database[source]
      if source_list
        redis_t Array, source_list
        value = source_list.pop
        @database.delete source if source_list.empty?
        redis_LPUSH destination, value
        return value
      end
      redis_t NilClass, Array, @database[destination]
      df = DeferredPop.new @database, redis_pos_i(timeout), source
      df.errback {send_redis Response::NIL_MB}
      df.callback do |key, value|
        redis_LPUSH destination, value
        send_redis value
      end
      df
    end
    
    def redis_RPUSH key, value
      list = @database[key]
      redis_t NilClass, Array, list
      (@database.blocked_pops[key] ||= []).each do |deferrable|
        deferrable.succeed key, value
        return 0
      end
      list = @database[key] = [] unless list
      list.push(value).size
    end

    def redis_LPUSH key, value
      list = @database[key]
      redis_t NilClass, Array, list
      (@database.blocked_pops[key] ||= []).each do |deferrable|
        deferrable.succeed key, value
        return 0
      end
      list = @database[key] = [] unless list
      list.unshift(value).size
    end

    def redis_LPUSHX key, value
      list = @database[key]
      return 0 unless Array === list and list.size > 0
      redis_LPUSH key, value
      list.size
    end

    def redis_RPUSHX key, value
      list = @database[key]
      return 0 unless Array === list and list.size > 0
      redis_RPUSH key, value
      list.size
    end
    
    def redis_LINSERT key, mode, pivot, value
      list = @database[key]
      index = list.find_index pivot
      return -1 unless index
      case mode.upcase
      when 'BEFORE'
        list[index,0] = value
      when 'AFTER'
        list[index+1,0] = value
      else
        raise 'only BEFORE|AFTER supported'
      end
      list.size
    end
    
    def redis_RPOP key
      list = @database[key]
      return nil unless list
      value = list.pop
      @database.delete key if list.empty?
      value
    end

    def redis_LPOP key
      list = @database[key]
      return nil unless list
      value = list.shift
      @database.delete key if list.empty?
      value
    end

    def redis_LLEN key
      list = @database[key] || []
      redis_t Array, list
      list.size
    end

    def redis_LINDEX key, index
      list = @database[key] || []
      redis_t Array, list
      list[redis_i index]
    end

    def redis_LSET key, index, value
      list = @database[key] || []
      redis_t Array, list
      raise 'out of range' unless list.size > redis_i(index).abs
      list[redis_i index] = value
    end
    
    def redis_LREM key, count, value
      list = @database[key] || []
      count = redis_i count
      size = list.size
      if count == 0
        list.delete value
      elsif count < 0
        i = list.size
        while i > 0 and count < 0
          i -= 1
          if list[i] == value
            list.delete_at i
            count += 1
          end
        end
      else # count > 0
        i = 0
        while i < list.size and count > 0
          if list[i] == value
            list.delete_at i 
            count -= 1
          else
            i += 1
          end
        end
      end
      size - list.size
    end
      
  end
end
