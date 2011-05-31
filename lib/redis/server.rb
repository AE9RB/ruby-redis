require_relative '../redis'
require_relative 'config'
require_relative 'protocol'
require_relative 'keys'
require_relative 'strings'
require_relative 'lists'
require_relative 'sets'

require 'eventmachine'

class Redis
  class Server < EventMachine::Connection
    
    include Protocol
    
    def initialize options=nil
      @options = options || Config.new
      @database = Redis.databases[0]
      authorize unless options[:requirepass]
      super()
    end
    
    def authorize
      return if @authorized
      extend Keys
      extend Strings
      extend Lists
      extend Sets
      @authorized = true
    end
    
    def redis_AUTH password
      if password == @options[:requirepass]
        authorize
        Response::OK
      else
        raise 'invalid password'
      end
    end

    def redis_SELECT db_index
      database = Redis.databases[db_index.to_redis_i]
      raise 'index out of range' unless database
      @database = database
      Response::OK
    end
    
    def redis_FLUSHDB
      @database.clear
      Response::OK
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
        "Ruby #{RUBY_VERSION}",
        1,
      ]
    end
    
  end
end


if __FILE__ == $0
require_relative 'test'

end
