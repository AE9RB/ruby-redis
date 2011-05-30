require_relative 'buftok'

class Redis
  
  # Use to respond with raw protocol
  #  Response["+#{data}\n\r"]
  #  Response::OK
  class Response < Array
    OK = self["+OK\r\n"]
    PONG = self["+PONG\r\n"]
    NIL = self["$-1\r\n"]
    FALSE = self[":0\r\n"]
    TRUE = self[":1\r\n"]
  end
  
  module Protocol
  
    def initialize *args
      @buftok = BufferedTokenizer.new
      super
    end
    
    # Redis commands are methods on the connection object.
    # Most commands aren't mixed in until after authentication.
    
    def redis_PING
      Response::PONG
    end

    def redis_ECHO str
      str
    end

    def redis_QUIT
      send_data Response::OK[0]
      close_connection_after_writing
      Response[] # send no more
    end

    # Companion to send_data.
    def send_redis data
      # data = data.to_a.flatten(1) if Hash === data #TODO better
      if nil == data
        send_data Response::NIL[0]
      elsif false == data
        send_data Response::FALSE[0]
      elsif true == data
        send_data Response::TRUE[0]
      elsif Numeric === data
        send_data ":#{data}\r\n"
      elsif String === data
        send_data "$#{data.size}\r\n"
        send_data data
        send_data "\r\n"
      elsif Response === data
        data.each do |item|
          send_data item
        end
      elsif Array === data
        send_data "*#{data.size}\r\n"
        data.each do |item|
          if String === item
            send_data "$#{item.size}\r\n"
            send_data item
            send_data "\r\n"
          else
            send_data Response::NIL[0]
          end
        end
      else
        raise "#{data.class} is not a redis type"
      end
    end
  
    # Process incoming redis protocol
    def receive_data data
      @buftok.extract(data) do |command, *arguments|
        # next if command.empty?
        # Redis.logger.warn "#{command.dump} #{arguments.collect{|a|a.dump}.join ' '}"
        begin
          send_redis send "redis_#{command.upcase}", *arguments
        rescue Exception => e
          if NoMethodError===e and e.message.index "undefined method `redis_#{command.upcase}'"
            send_data "-ERR unknown command #{command.dump}\r\n"
          else
            # Redis.logger.warn "#{command.dump}: #{e.class}:/#{e.backtrace[0]} #{e.message}"
            # e.backtrace[1..-1].each {|bt|Redis.logger.warn bt}
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
