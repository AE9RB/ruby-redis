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
      raise 'not suported' unless type.downcase == 'object'
      "{@database.key.class}"
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
