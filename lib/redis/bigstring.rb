class Redis
  class BigString < Array
    
    #TODO consider raising on object id or other method to prevent using as a key
    
    def initialize *args
      super
      @split = nil
      @pending = nil
    end
    
    def to_s
      replace [join] unless size == 1
      return first
    end
    
    def to_i
      to_s.to_i
    end
    
    def restore_split
      if @split
        replace [@split.join("\n")]
        @split = nil
      end
    end
        
    def read_redis length
      
      if @split
        if @split[0].size >= length
          result = @split.shift[0...length]
          if @split.size == 1
            self[0] = @split[0]
            @split = nil
          end
          return result
        end
        restore_split
      end

      unless @pending
        size = reduce(0){|x,y|x+y.size}
        return nil unless size >= length
        @pending = dup
        clear
        remainder = size - length
        if remainder > 0
          last_string = @pending[-1]
          @pending[-1] = last_string[0...-remainder]
          push last_string[-remainder..-1]
        end
      end
      
      # eat newline
      return nil unless gets_redis
      result = @pending
      @pending = nil
      result
    end

    def gets_redis
      unless @split
        @split = join.split "\n", -1
        clear
      end
      if @split.size > 1
        result = @split.shift.chomp "\n"
      else
        result = nil
      end
      if @split.size == 1
        self[0] = @split[0]
        @split = nil
      end
      result
    end
    
  end
end

if __FILE__ == $0
require_relative 'test'

end
