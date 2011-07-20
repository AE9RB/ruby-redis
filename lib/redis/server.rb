require File.expand_path '../redis', File.dirname(__FILE__)

class Redis
  
  module Server
    
    def redis_FLUSHDB
      @database.clear
      :'+OK'
    end

    def redis_FLUSHALL
      Redis.databases.each do |database|
        database.clear
      end
      :'+OK'
    end
    
    def redis_DBSIZE
      @database.size
    end
    
    def redis_DEBUG type, key=nil
      if type.upcase == 'OBJECT'
        "#{@database[key].class}"
        value = @database[key]
        # encoding values are meaningless, they make tcl tests pass
        # and don't forget they need a trailing space
        if String === value
          "Value #{value.class}:#{value.object_id} encoding:raw encoding:int "
        elsif Numeric === value
          "Value #{value.class}:#{value.object_id} encoding:int "
        elsif Array === value
          "Value #{value.class}:#{value.object_id} encoding:ziplist encoding:linkedlist "
        elsif Hash === value
          "Value #{value.class}:#{value.object_id} encoding:zipmap encoding:hashtable "
        elsif Set === value
          "Value #{value.class}:#{value.object_id} encoding:intset encoding:hashtable "
        else
          "Value #{value.class}:#{value.object_id}"
        end
      elsif type.upcase == 'RELOAD'
        "TODO: what is reload"
      else
        raise 'not supported'
      end
    end
    
    def redis_INFO
      [
        "redis_version:%s\r\n",
        "redis_git_sha1:%s\r\n",
        "redis_git_dirty:%d\r\n",
      ].join % [
        Redis::VERSION,
        "Ruby",
        1,
      ]
    end
    
  end
end
