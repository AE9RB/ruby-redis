require_relative 'buftok'

class Redis
  module Protocol
  
    def initialize *args
      @buftok = BufferedTokenizer.new
      super
    end
    
    # Redis commands are methods on the connection object.
    # Most commands aren't mixed in until after authentication.
    # Arity is checked by Ruby.
    
    def redis_PING
      send_data "+PONG\r\n"
    end

    def redis_ECHO str
      send_redis str
    end

    def redis_QUIT
      send_data "+OK\r\n"
      close_connection_after_writing
    end

    # Companion to send_data.
    def send_redis data
      if nil == data
        send_data "$-1\r\n"
      elsif String === data
        send_data "$#{data.size}\r\n"
        send_data data
        send_data "\r\n"
      elsif Numeric === data
        send_data ":#{data}\r\n"
      else
        raise 'not a redis type'
      end
    end
  
    # Process incoming redis protocol
    def receive_data data
      @buftok.extract(data) do |command, *arguments|
        next if command.empty?
        begin
          send "redis_#{command.upcase}", *arguments
        rescue Exception => e
          if NoMethodError===e and e.message.index "undefined method `redis_#{command.upcase}'"
            send_data "-ERR unknown command #{command.dump}\r\n"
          else
            # Redis.logger.warn "#{e.class} : #{e.message}"
            # e.backtrace.each {|bt|Redis.logger.warn bt}
            send_data "-ERR #{e.message}\r\n"
          end
        end
      end
    rescue Exception => e
      @buftok.flush
      send_data "-ERR #{e.message}\r\n"
    end

  end
end

if __FILE__ == $0
require_relative 'test'

end
