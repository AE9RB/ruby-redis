require 'eventmachine'

class Redis
  
  module Lists
    
    class DeferredPop
      include EventMachine::Deferrable
      
      def initialize database, timeout_secs, *keys
        @database = database
        @keys = keys
        timeout timeout_secs
        errback { unbind }
        callback { unbind }
        keys.each do |key|
          (@database.lists_df[key] ||= []).push self
        end
      end
      
      def unbind
        @keys.each do |key|
          key_df_list = @database.lists_df[key]
          next unless key_df_list
          key_df_list.delete_if { |e| e == self }
        end
      end
      
    end
    
    #TODO The redis tests require a specific error so we can't
    # let Ruby do the error handling.  Make better tests so we
    # kill the rampant raise 'wrong kind' ...
    
    def redis_LRANGE key, first, last
      (@database[key] || [])[first.to_redis_i..last.to_redis_i]
    end
    
    def redis_BRPOP *args
      timeout = args.pop.to_redis_pos_i
      args.each do |key|
        list = @database[key]
        return list.pop if list and list.size > 0
      end
      df = DeferredPop.new(@database, timeout, *args)
      df.errback { send_redis Response::NIL_MB }
      df.callback { |key, value| send_redis [key, value] }
      df
    end
    
    def redis_BLPOP *args
      timeout = args.pop.to_redis_pos_i
      args.each do |key|
        list = @database[key]
        return list.shift if list and list.size > 0
      end
      df = DeferredPop.new(@database, timeout, *args)
      df.errback { send_redis Response::NIL_MB }
      df.callback { |key, value| send_redis [key, value] }
      df
    end
    
    def redis_BRPOPLPUSH source, destination, timeout
      source_array = @database[source]
      if source_array
        raise 'wrong kind' unless Array === source_array
        if source_array.size > 0
          value = source_array.pop
          redis_LPUSH destination, value
          return value
        end
      end
      raise 'wrong kind' unless !@database[destination] or Array === @database[destination]
      timeout = timeout.to_redis_pos_i
      df = EventMachine::DefaultDeferrable.new
      df.timeout timeout if timeout > 0
      df.errback {send_redis Response::NIL_MB}
      df.callback do |key, value|
        (@database.lists_df[source] || []).delete_if{|e|e==df}
        redis_LPUSH destination, value
        send_redis value
      end
      (@database.lists_df[source] ||= []).push df
      df
    end
    
    def redis_RPUSH key, value
      entry = @database[key] ||= []
      raise 'wrong kind' unless Array === entry
      (@database.lists_df[key] ||= []).each { |x| x.succeed key, value; return 0 } 
      entry.push(value).size
    end

    def redis_LPUSH key, value
      entry = @database[key] ||= []
      # raise "#{key} #{value}" unless Array === entry
      raise 'wrong kind' unless Array === entry
      (@database.lists_df[key] ||= []).each { |x| x.succeed key, value; return 0 } 
      entry.unshift(value).size
    end
    
    def redis_RPOP key
      (@database[key] || []).pop
    end

    def redis_LLEN key
      (@database[key] || []).size
    end

    def redis_LINDEX key, index
      (@database[key] || [])[index.to_redis_i]
    end
      
  end
end

if __FILE__ == $0
require_relative 'test'

end
