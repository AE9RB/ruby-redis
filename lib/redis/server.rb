require_relative '../redis'
require_relative 'protocol'
require_relative 'database'
require_relative 'strings'

require 'eventmachine'

class Redis
  class Server < EventMachine::Connection
    
    include Protocol
    include Database
    
    def initialize options={}
      @options = options
      authorize unless options[:requirepass]
      super()
    end
    
    def authorize *args
      return if @authorized
      extend Strings
      @authorized = true
    end
    
    def redis_AUTH password
      if password == @options[:requirepass]
        authorize
        send_data "+OK\r\n"
      else
        send_data "-ERR invalid password\r\n"
      end
    end

    def redis_INFO *args
      info = ([
        "redis_version:%s\r\n",
        "redis_git_sha1:%s\r\n",
        "redis_git_dirty:%d\r\n",
      ].join) % [
        Redis::VERSION,
        'fakesha',
        1,
      ]
      send_data "$#{info.size}\r\n#{info}\r\n"
    end
    
  end
end


if __FILE__ == $0
require_relative 'test'

end
