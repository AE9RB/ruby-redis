class Redis
  module Protocol
  
    def initialize
      @binary_size = nil
      @remainder = ''
      @multi_bulk = 0
      @command = nil
      @arguments = []
      super
    end
    
    def redis_PING *args
      send_data "+PONG\r\n"
    end
    
    # process an entire frame of redis protocol
    def receive_redis str
      if @command
        @arguments << str
      elsif str and !str.empty?
        @command = str
        #TODO detect telnet shortcuts
      end
      if @multi_bulk > 0
        @multi_bulk -= 1
        return unless @multi_bulk == 0
      end
      if @command and !@command.empty?
        begin
          begin
            send("redis_#{@command.upcase}", *@arguments)
          rescue NoMethodError => e
            raise e unless e.message =~ Regexp.new("redis_#{@command.upcase}")
            send_data "-ERR unknown command '#{@command.gsub /'/, "\\'"}'\r\n"
          end
        rescue Exception => e
          # Redis.logger.warn e.class
          # Redis.logger.warn e.message
          # e.backtrace.each {|bt|Redis.logger.warn bt}
          send_data "-ERR #{e.message}\r\n"
        end
      end
      @command = nil
      @arguments = []
    end
  
    def receive_data data
      #TODO limit data + remainder
      # Voodoo with the -1
      entities = data.split "\n", -1
      entities[0] = @remainder + entities[0]
      @remainder = entities.pop
      bin = [] #TODO class RedisString
      entities.each do |e|
        if @binary_size
          # Two paths for performance optimization
          if e.size >= @binary_size and bin.empty?
            receive_redis e[0...@binary_size]
            @binary_size = nil
          else
            bin << e
            bin_size = bin.reduce(0){|x,y|x+y.size+1}-1
            if bin_size >= @binary_size
              receive_redis bin.join("\n")[0...@binary_size]
              @binary_size = nil
              bin = []
            end
          end
        else
          case e[0]
          when '*'
            @multi_bulk = e[1..-1].to_i
            if @multi_bulk > 1024*1024
              @multi_bulk = 0
              send_data "-ERR Protocol error: invalid multibulk length\r\n"
            end
          when '$'
            @binary_size = e[1..-1].to_i
            if @binary_size == -1
              receive_redis nil
              @binary_size = nil
            elsif (@binary_size == 0 and e[1] != '0') or @binary_size < -1 or @binary_size > 512*1024*1024
              send_data "-ERR Protocol error: invalid bulk length\r\n"
              @binary_size = nil
            end
          else
            # possible command
            receive_redis e.chomp
          end
        end
      end
      @remainder += bin.reduce(''){|x,y|x+y+"\n"} #TODO class RedisString
    end

  end
end

if __FILE__ == $0
require_relative 'test'

end
