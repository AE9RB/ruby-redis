class Redis
  module Commands
  
    @@databases = [{}]
    @@redis = @@databases[0]
  
    def run_command
      case @command.upcase
      when 'PING'
        send_data "+PONG\r\n"
      when 'SELECT'
        #TODO test limits
        @@redis = (@@databases[@arguments[0].to_i] ||= {})
        send_data "+OK\r\n"
      when 'AUTH'
        #TODO
        send_data "-ERR\r\n"
      when 'INCR'
        key = @arguments[0]
        value = (@@redis[key] || 0) + 1
        @@redis[key] = value
        send_data ":#{value}\r\n"
      when 'SET'
        @@redis[@arguments[0]] = @arguments[1]
        send_data "+OK\r\n"
      when 'MSET'
        @@redis.merge! Hash[*@arguments]
        send_data "+OK\r\n"
      when 'GET'
        value = @@redis[@arguments[0]]
        if value==nil
          send_data "$-1\r\n"
        else
          send_data "$#{value.size}\r\n#{value}\r\n"
        end
      when nil
        raise "empty command"
      else
        send_data "-ERR unknown command '#{@command.gsub /'/, "\\'"}'\r\n"
        #TODO handy for testing
        # p "unsupported command: #{@command.inspect}"
        # raise "unsupported command: #{@command.inspect}"
      end
    end
  
  end
end

if __FILE__ == $0
require_relative 'test'

end
