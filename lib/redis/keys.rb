class Redis
  module Keys
  
    def redis_KEYS pattern
      send_redis(@database.keys.find_all do |key|
        File.fnmatch pattern, key
      end.to_a)
    end
    
    def redis_DEL *keys
      count = 0
      keys.each { |key| count += 1 unless @database.delete(key){nil} == nil }
      send_redis count
    end
      
  end
end

if __FILE__ == $0
require_relative 'test'

end
