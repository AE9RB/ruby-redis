require 'set'

class Redis
  module Sets
  
    def redis_SADD key, member
      record = (@database[key] ||= Set.new)
      return false if record.include? member
      record.add member
      true
    end
      
  end
end

if __FILE__ == $0
require_relative 'test'

end
