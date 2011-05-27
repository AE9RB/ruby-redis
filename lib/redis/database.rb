class Redis
  module Database
  
    @@databases = [{}]
    
    def initialize
      @database = @@databases[0]
      super
    end
    
    def redis_SELECT db_index
      db_index = db_index.to_i
      if db_index < 0 or db_index >= @options[:databases]
        send_data "-ERR\r\n"
      else
        @database = @@databases[db_index] ||= {}
        send_data "+OK\r\n"
      end
    end
    
  end
end

if __FILE__ == $0
require_relative 'test'

end
