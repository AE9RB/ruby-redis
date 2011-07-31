%w{reader sender version config logger strict connection protocol database 
   server keys strings lists sets zsets hashes pubsub}.each do |file|
     require File.expand_path file, File.dirname(__FILE__)
end

module Redis
  class Bin

    class RubyRedisServer < EventMachine::Connection

      include Strict
      include Connection
      include Protocol
      include Sender
      
      def initialize logger, databases, config={}
        @logger = logger
        @databases = databases
        @database = databases[0]
        @config = config
        super
      end
      
      def post_init
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

      Dir.chdir config[:dir]
      
      if config[:logfile] == 'stdout'
        logger = Logger.new STDOUT
      else
        logger = Logger.new config[:logfile] 
      end

      if config[:loglevel] == 'debug'
        logger.level = Logger::DEBUG
      elsif config[:loglevel] == 'notice'
        logger.level = Logger::NOTICE
      elsif config[:loglevel] == 'warning'
        logger.level = Logger::WARNING
      elsif config[:loglevel] != 'verbose'
        raise "Invalid log level. Must be one of debug, notice, warning, verbose."
      else
        logger.level = Logger::INFO
      end

      if show_no_config_warning
        logger.warn "Warning: no config file specified, using the default config. In order to specify a config file use 'ruby-redis /path/to/redis.conf'"
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
        rescue StandardError => e
          logger.error e.message
        end
      end
      
      EventMachine.run {

        databases = Array.new(config[:databases]) {Database.new}
        started_message = "Server started, Ruby Redis version %s" % Redis::VERSION
  
        if config[:unixsocket]
          EventMachine::start_server config[:unixsocket], RubyRedisServer, logger, databases, config
          logger.notice started_message
          logger.notice "The server is now ready to accept connections at %s" % config[:unixsocket]
        else
          EventMachine::start_server config[:bind], config[:port], RubyRedisServer, logger, databases, config
          logger.notice started_message
          logger.notice "The server is now ready to accept connections on port %d" % config[:port]
        end
        
        # The test suite blocks until it gets the pid from the log.
        logger.flush

      }
      
    end
  end
end
