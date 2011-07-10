require_relative '../redis'

class Redis
  
  # This should always be included before Strict
  # Don't go strict if you want to see Ruby messages for the errors.
  # This is faster and allows for experimentation with duck-typing.
  module NotStrict

    def strict &block
    end

    def redis_f val
      val_downcase = val.downcase
      if val_downcase == '-inf'
        -1.0/0
      elsif val_downcase =~ /^[+]?inf$/
        1.0/0
      elsif !(self =~ /^[ +]?[0-9.e-]*$/)
        raise "weight value is not a double"
      else
        to_f
      end
    end
    
    def redis_i val, msg = nil
      val.to_i
    end
    
    def redis_pos_i val, msg = 'out of range because is negative'
      val = redis_i val
      raise msg if val < 0
      val
    end
    
  end
  
  # Including Strict allows the ruby-redis server to pass redis tests.
  module Strict

    def strict &block
      yield if block_given?
    end

    def redis_i val, msg = 'out of range because not an integer'
      raise msg unless self =~ /^[ +-]?[0-9]*$/
      super
    end
    
  end
  
end

#TODO retire

class ::String

  def to_redis_f
    self_downcase = self.downcase
    Redis.logger.warn self_downcase
    if self_downcase == '-inf'
      -1.0/0
    elsif self_downcase =~ /^[+]?inf$/
      1.0/0
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
