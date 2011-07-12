require_relative '../redis'
require_relative 'database'
require_relative 'protocol'
require_relative 'server'
require_relative 'keys'
require_relative 'strings'
require_relative 'lists'
require_relative 'sets'
require_relative 'zsets'
require_relative 'hashes'
require_relative 'pubsub'
require_relative 'strict'

require 'eventmachine'

class Redis
  class Connection < EventMachine::Connection
    
    include NotStrict
    include Protocol
    
    def initialize password=nil
      @password = password
      @database = Redis.databases[0]
      authorize unless @password
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
      extend PubSub
      @authorized = true
    end
    
    def redis_AUTH password
      raise 'invalid password' unless password == @password
      authorize
      Response::OK
    end

    def redis_SELECT db_index
      database = Redis.databases[redis_i db_index]
      raise 'invalid DB index' unless database
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