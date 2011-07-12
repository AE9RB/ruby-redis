require_relative '../redis'

class Redis
  
  # This is faster and allows for experimentation with duck-typing.
  module NotStrict

    def redis_t *args
    end

    def redis_f val, msg = nil
      if Numeric === val
        val
      else
        val_downcase = val.downcase
        if val_downcase == '-inf'
          -1.0/0
        elsif val_downcase =~ /^[+]?inf$/
          1.0/0
        else
          val.to_f
        end
      end
    end
    
    def redis_i val, msg = nil
      val.to_i
    end
    
    def redis_pos_i val, msg = 'value is negative'
      val = redis_i val # may call strict
      raise msg if val < 0
      val
    end
    
  end
  
  # Strict version allows the ruby-redis server to pass redis tests.
  module Strict
    include NotStrict

    def redis_t *args
      val = args.pop
      msg = 'Operation against a key holding the wrong kind of value'
      unless Class === args.last
        msg = val
        val = args.pop
      end
      args.each do |klass|
        return if klass === val
      end
      raise msg
    end

    def redis_f val, msg = 'value is not a double'
      raise msg+val.to_s.dump unless Numeric === val or val =~ /^[ +-]?([0-9.e-]*|inf)$/i
      super
    end

    def redis_i val, msg = 'value is not an integer or out of range'
      raise msg unless Integer === val or val =~ /^[ +-]?[0-9]*$/
      super
    end
    
  end
  
end
