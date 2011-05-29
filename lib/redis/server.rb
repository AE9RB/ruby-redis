require_relative '../redis'
require_relative 'protocol'
require_relative 'keys'
require_relative 'strings'
require_relative 'lists'

require 'eventmachine'

class Redis
  class Server < EventMachine::Connection
    
    include Protocol
    
    def initialize options={}
      @database = Redis.databases[0]
      @options = options
      authorize unless options[:requirepass]
      super()
    end
    
    def authorize
      return if @authorized
      extend Keys
      extend Strings
      extend Lists
      @authorized = true
    end
    
    def redis_AUTH password
      if password == @options[:requirepass]
        authorize
        send_data "+OK\r\n"
      else
        raise 'invalid password'
      end
    end

    def redis_SELECT db_index
      db_index = db_index.to_i
      if db_index < 0 or db_index >= @options[:databases]
        raise 'index out of range'
      else
        @database = Redis.databases[db_index] ||= {}
        send_data "+OK\r\n"
      end
    end
    
    def redis_DBSIZE
      send_redis @database.size
    end
    
    def redis_INFO
      send_redis([
        "redis_version:%s\r\n",
        "redis_git_sha1:%s\r\n",
        "redis_git_dirty:%d\r\n",
      ].join % [
        Redis::VERSION,
        'Ruby',
        1,
      ])
    end
    
  end
end


if __FILE__ == $0
require_relative 'test'

end
