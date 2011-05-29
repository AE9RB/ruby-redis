require_relative 'redis/database'

class Redis
  
  VERSION = '0.0.0.pre'
  
  def self.databases
    @@databases ||= [Database.new]
  end
    
end

class ::String
  def to_redis_i
    raise 'invalid integer' unless self =~ /^-?[0-9]*$/
    to_i
  end
end

class ::Numeric
  def to_redis_i
    to_i
  end
end


if __FILE__ == $0
require_relative 'test'

end
