require File.expand_path '../redis', File.dirname(__FILE__)
require_relative 'config'
require_relative 'connection'
require_relative 'logger'
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

class Redis
  class Bin

    class RedisServer < Cool.io::TCPSocket
      include Strict
      include Connection
      include Protocol
      
      def initialize io, password
        @password = password
        @database = Redis.databases[0]
        authorize nil
        super io
      end
      
      def authorize password
        return false unless password == @password
        return true if @redis_authorized
        extend Server
        extend Keys
        extend Strings
        extend Lists
        extend Sets
        extend ZSets
        extend Hashes
        extend PubSub
        @redis_authorized = true
      end
      
    end
    
    def self.server

      if ARGV==['-v'] or ARGV==['--version']
        print "Redis server version %s (Ruby)\n" % Redis::VERSION
        exit 0
      end

      if ARGV==['--help'] or ARGV.size > 1
        STDERR.print "Usage: ruby-redis [/path/to/redis.conf]\n"
        STDERR.print "       ruby-redis - (read config from stdin)\n"
        exit 1
      end

      show_no_config_warning = (ARGV.size == 0)

      config = Config.new(ARGV.empty? ? [] : ARGF)

      Dir.chdir config[:dir]

      Redis.logger config[:logfile] unless config[:logfile] == 'stdout'

      #TODO
      # Set server verbosity to 'debug'
      # it can be one of:
      # debug (a lot of information, useful for development/testing)
      # verbose (many rarely useful info, but not a mess like the debug level)
      # notice (moderately verbose, what you want in production probably)
      # warning (only very important / critical messages are logged)
      # loglevel verbose

      if show_no_config_warning
        Redis.logger.warn "Warning: no config file specified, using the default config. In order to specify a config file use 'ruby-redis /path/to/redis.conf'"
      end

      (0...config[:databases]).each do |db_index|
        Redis.databases[db_index] ||= Database.new
      end

      event_loop = Cool.io::Loop.default
      Cool.io::TCPServer.new('127.0.0.1', config[:port], RedisServer, config[:requirepass]).attach(event_loop)
      # Cool.io::TCPServer.new(ADDR, PORT, EchoServerConnection).attach(event_loop)
      
      Redis.logger.notice "Server started, Ruby Redis version %s" % Redis::VERSION
      Redis.logger.notice "The server is now ready to accept connections on port %d" % config[:port]
      # The test suite blocks until it gets the pid from the log.
      Redis.logger.flush
      
      event_loop.run
      
    end
  end
end
