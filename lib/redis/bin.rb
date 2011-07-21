%w{reader sender version config logger strict connection protocol database 
   server keys strings lists sets zsets hashes pubsub}.each do |file|
     require File.expand_path file, File.dirname(__FILE__)
end

class Redis
  class Bin

    class RubyRedisServer < EventMachine::Connection

      include Strict
      include Connection
      include Protocol
      include Sender
      
      def initialize config={}
        @config = config
        super
      end
      
      def post_init
        @database = Redis.databases[0]
        authorized nil
        set_comm_inactivity_timeout @config[:timeout]
      end
      
      def authorized password
        return true if @authorized
        return false unless @config[:requirepass] == password
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

      if config[:loglevel] == 'debug'
        Redis.logger.level = Logger::DEBUG
      elsif config[:loglevel] == 'notice'
        Redis.logger.level = Logger::NOTICE
      elsif config[:loglevel] == 'warning'
        Redis.logger.level = Logger::WARNING
      elsif config[:loglevel] != 'verbose'
        raise "Invalid log level. Must be one of debug, notice, warning, verbose."
      else
        Redis.logger.level = Logger::INFO
      end

      Dir.chdir config[:dir]
      
      Redis.logger config[:logfile] unless config[:logfile] == 'stdout'

      if show_no_config_warning
        Redis.logger.warn "Warning: no config file specified, using the default config. In order to specify a config file use 'ruby-redis /path/to/redis.conf'"
      end
      
      (0...config[:databases]).each do |db_index|
        Redis.databases[db_index] ||= Database.new
      end

      if config[:daemonize]
        exit!(0) if fork
        Process::setsid
        exit!(0) if fork
        STDIN.reopen("/dev/null")
        STDOUT.reopen("/dev/null", "w")
        STDERR.reopen("/dev/null", "w")
        begin
          File.open(config[:pidfile], 'w') do |io|
            io.write "%d\n" % Process.pid
          end
        rescue Exception => e
          Redis.logger.error e.message
        end
      end
      
      EventMachine.run {

        started_message = "Server started, Ruby Redis version %s" % Redis::VERSION
  
        if config[:unixsocket]
          EventMachine::start_server config[:unixsocket], RubyRedisServer, config
          Redis.logger.notice started_message
          Redis.logger.notice "The server is now ready to accept connections at %s" % config[:unixsocket]
        else
          EventMachine::start_server config[:bind], config[:port], RubyRedisServer, config
          Redis.logger.notice started_message
          Redis.logger.notice "The server is now ready to accept connections on port %d" % config[:port]
        end
        
        # The test suite blocks until it gets the pid from the log.
        Redis.logger.flush

      }
      
    end
  end
end
