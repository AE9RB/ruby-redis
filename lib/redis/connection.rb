require_relative '../redis'
require_relative 'config'
require_relative 'protocol'
require_relative 'server'
require_relative 'keys'
require_relative 'strings'
require_relative 'lists'
require_relative 'sets'
require_relative 'zsets'
require_relative 'hashes'

require 'eventmachine'

class Redis
  class Connection < EventMachine::Connection
    
    include Protocol
    
    def initialize options=nil
      @options = options || Config.new
      @database = Redis.databases[0]
      authorize unless options[:requirepass]
      super()
    end
    
    def authorize
      return if @authorized
      extend Server
      extend Keys
      extend Strings
      extend Lists
      extend Sets
      extend ZSets
      extend Hashes
      @authorized = true
    end
    
    def redis_AUTH password
      raise 'invalid password' unless password == @options[:requirepass]
      authorize
      Response::OK
    end

    def redis_SELECT db_index
      database = Redis.databases[db_index.to_redis_i]
      raise 'index out of range' unless database
      @database = database
      Response::OK
    end
    
    def redis_PING
      Response::PONG
    end

    def redis_ECHO str
      str
    end

    def redis_QUIT
      send_redis Response::OK
      raise CloseConnection
    end
    
  end
end