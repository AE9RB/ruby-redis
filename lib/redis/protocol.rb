require_relative 'bigstring'

class Redis
  module Protocol
  
    def initialize
      @binary_size = nil
      @str = BigString.new
      @multi_bulk = 0
      @command = nil
      @arguments = []
      super
    end
    
    def send_redis data
      if nil == data
        send_data "$-1\r\n"
      elsif String === data
        send_data "$#{data.size}\r\n"
        send_data data
        send_data "\r\n"
      elsif BigString === data
        data_size = data.reduce(0){|x,y|x+y.size}
        send_data "$#{data_size}\r\n"
        data.each {|d| send_data d }
        send_data "\r\n"
      elsif Numeric === data
        send_data ":#{data}\r\n"
      else
        # development helper
        raise 'not a redis type'
      end
    end

    # Redis commands are methods on the connection object.
    # Most commands aren't mixed in until after authentication.
    # Arity is checked by Ruby.
    def redis_PING
      send_data "+PONG\r\n"
    end
  
    # process an entire frame of redis protocol
    def receive_redis str
      if @command
        @arguments << str
      else
        @command = str
        #TODO detect telnet shortcuts
      end
      if @multi_bulk > 0
        @multi_bulk -= 1
        return unless @multi_bulk == 0
      end
      if @command and !@command.empty?
        begin
          upcase_command_string = @command.to_s.upcase
          begin
            send("redis_#{@command.to_s.upcase}", *@arguments)
          rescue NoMethodError => e
            raise e unless e.message.index "undefined method `redis_#{@command.to_s.upcase}'"
            send_data "-ERR unknown command #{@command.to_s.dump}\r\n"
          end
        rescue Exception => e
          Redis.logger.warn e.class
          Redis.logger.warn e.message
          e.backtrace.each {|bt|Redis.logger.warn bt}
          send_data "-ERR #{e.message}\r\n"
        end
      end
      @command = nil
      @arguments = []
    end
    
    def receive_data data
      @str.restore_split
      @str << data
      while true
        if @binary_size
          s = @str.read_redis @binary_size
          break unless s
          @binary_size = nil
          receive_redis s
        else
          line = @str.gets_redis
          break unless line
          case line[0]
          when '*'
            @multi_bulk = line[1..-1].to_i
            if @multi_bulk > 1024*1024
              @multi_bulk = 0
              send_data "-ERR Protocol error: invalid multibulk length\r\n"
            end
          when '$'
            @binary_size = line[1..-1].to_i
            if @binary_size == -1
              receive_redis nil
              @binary_size = nil
            elsif (@binary_size == 0 and line[1] != '0') or @binary_size < 0 or @binary_size > 512*1024*1024
              send_data "-ERR Protocol error: invalid bulk length\r\n"
              @binary_size = nil
            end
          else
            receive_redis line
          end
        end
      end
    end

  end
end

if __FILE__ == $0
require_relative 'test'

end
