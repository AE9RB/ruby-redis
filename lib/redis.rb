class Redis
  
  VERSION = '0.0.0.pre'
  
  def self.databases
    @@databases ||= [{}]
  end
    
end

class ::String
  def to_redis_i
    raise 'invalid integer' if self =~ /\D/
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
