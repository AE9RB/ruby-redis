module Redis
  module Protocol
    
    def initialize *args
      @reader = Reader.new
      @multi = nil
      @deferred = nil
      @watcher = nil
      super
    end
    
    def unbind
      @deferred.unbind if @deferred
      @watcher.unbind if @watcher
      super
    end
    
    # Process incoming redis protocol
    def receive_data data
      return unless @reader
      @reader.feed data
      until (strings = @reader.gets) == false
        if @multi and !%w{WATCH DISCARD MULTI EXEC DEBUG}.include?(strings[0].upcase)
          @multi << strings
          send_redis :'+QUEUED'
        else
          result = __send__ "redis_#{strings[0].upcase}", *strings[1..-1]
          if Integer === result
            send_data ":#{result}\r\n"
          elsif EventMachine::Deferrable === result
            @deferred.unbind if @deferred and @deferred != result
            @deferred = result
          elsif result == :quit
            @reader = nil
            close_connection_after_writing
            break
          elsif result != :exec
            send_redis result
          end
        end
      end
    rescue StandardError, LoadError, SyntaxError => e
      # This sometimes comes in handy for the TCL tests
      # @logger.warn "#{e.class}:/#{e.backtrace[0]} #{e.message}"
      # e.backtrace[1..-1].each {|bt| @logger.warn bt}
      send_data "-ERR #{e.class.name}: #{e.message}\r\n" 
    end

    def redis_WATCH *keys
      raise 'WATCH inside MULTI is not allowed' if @multi
      @watcher ||= Database::Watcher.new
      @watcher.bind @database, *keys
      :'+OK'
    end
    
    def redis_UNWATCH
      if @watcher
        @watcher.unbind
        @watcher = nil
      end
      :'+OK'
    end

    def redis_MULTI
      raise 'MULTI nesting not allowed' if @multi
      @multi = []
      :'+OK'
    end
    
    def redis_DISCARD
      redis_UNWATCH
      @multi = nil
      :'+OK'
    end

    def redis_EXEC
      if @watcher
        still_bound = @watcher.bound
        redis_UNWATCH
        unless still_bound
          @multi = nil
          return :'*-1' 
        end
      end
      send_data "*#{@multi.size}\r\n"
      response = []
      @multi.each do |strings|
        begin
          result = __send__ "redis_#{strings[0].upcase}", *strings[1..-1]
        rescue StandardError, LoadError, SyntaxError => e
          result = e
        end
        if EventMachine::Deferrable === result
          result.unbind
          send_redis nil
        elsif Exception === result
          send_data "-ERR #{result.class.name}: #{result.message}"
        else
          send_redis result
        end
      end
      @multi = nil
      :exec
    end

  end
end
