require_relative 'redis/database'

class Redis
  
  VERSION = '0.0.1.dev'
  
  def self.databases
    @@databases ||= [Database.new]
  end
    
end

class ::String

  def to_redis_f
    self_downcase = self.downcase
    if self_downcase == '+inf'
      1.0/0
    elsif self_downcase == '-inf'
      -1.0/0
    else
      raise "weight value is not a double" unless self =~ /^[ +]?[0-9.e-]*$/
      to_f
    end
  end
  
  def to_redis_i
    raise 'not an integer' unless self =~ /^[ +-]?[0-9]*$/
    to_i
  end

  def to_redis_pos_i
    to_redis_i.to_redis_pos_i
  end
  
end

class ::Numeric

  def to_redis_f
    self
  end

  def to_redis_i
    to_i
  end

  def to_redis_pos_i
    i = to_i
    raise 'out of range because is negative' if i < 0
    i
  end
  
end

