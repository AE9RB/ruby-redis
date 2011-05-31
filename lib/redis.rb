require_relative 'redis/database'

class Redis
  
  VERSION = '0.0.0.pre'
  
  def self.databases
    @@databases ||= [Database.new]
  end
    
end

class ::String
  def to_redis_i
    raise 'not an integer' unless self =~ /^-?[0-9]*$/
    to_i
  end

  def to_redis_pos_i
    to_redis_i.to_redis_pos_i
  end
  
end

class ::Numeric
  def to_redis_i
    to_i
  end

  def to_redis_pos_i
    i = to_i
    raise 'out of range because is negative' if i < 0
    i
  end
  
end


if __FILE__ == $0
require_relative 'test'

end
