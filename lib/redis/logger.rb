require 'logger'

class Redis
  
  # Create log entry example:
  # Redis.logger.notice "Server started, Redis version %s (Ruby)" % Redis::VERSION
  # Change device example:
  # Redis.logger config[:logfile] unless config[:logfile] == 'stdout'
  def self.logger(logdev = nil, *opts)
    @@logger = nil if logdev
    @@logger ||= lambda {
      logger = Logger.new (logdev||STDOUT), *opts
      logger
    }.call
  end
  
  # Redis levels are: DEBUG < INFO < NOTICE < WARNING
  # This logger inserts support for NOTICE
  class Logger < ::Logger
    
    def initialize(logdev, *args)
      super
      @raw_logdev = logdev
      @default_formatter = proc { |severity, datetime, progname, msg|
        mark = case severity
        when 'DEBUG' then '.'
        when 'INFO' then '-'
        when 'NOTE' then '*'
        when 'WARN' then '#'
        else '!'
        end
        "[#{Process.pid}] #{datetime.strftime '%d %b %H:%H:%S'} #{mark} #{msg}\n"
      }
    end
    
    def flush
      @raw_logdev.flush if @raw_logdev.respond_to? :flush
    end
    
    module Severity
      # logger.rb says "max 5 char" for labels
      SEV_LABEL = %w(DEBUG INFO NOTE WARN ERROR FATAL ANY)
      DEBUG = 0
      INFO = 1
      NOTICE = 2
      WARN = 3
      ERROR = 4
      FATAL = 5
      UNKNOWN = 6
    end
    include Severity

    def notice(progname = nil, &block)
      add(NOTICE, nil, progname, &block)
    end
    def warn(progname = nil, &block)
      add(WARN, nil, progname, &block)
    end
    def error(progname = nil, &block)
      add(ERROR, nil, progname, &block)
    end
    def fatal(progname = nil, &block)
      add(FATAL, nil, progname, &block)
    end
    def unknown(progname = nil, &block)
      add(UNKNOWN, nil, progname, &block)
    end
    
    def notice?; @level <= NOTICE; end
    def warn?; @level <= WARN; end
    def error?; @level <= ERROR; end
    def fatal?; @level <= FATAL; end
        
    private
    
    def format_severity(severity)
      SEV_LABEL[severity] || 'ANY'
    end
    
  end
  
  
end
