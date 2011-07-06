require File.join(File.dirname(__FILE__), '../redis')

class Redis
  
  class BufferedTokenizer < Array

    class Error < StandardError
    end
    
    # Minimize the amount of memory copying.
    # Similar to EventMachine::BufferedTokenizer.
    # This will be ported to C when complete.
    
    #TODO max buffer size
    
    def initialize
      super()
      flush
    end
    
    def extract data  
      unshift_split if @split
      push data
      frame do |str|
        @elements << str
        if @remaining > 0
          @remaining -= 1
          next unless @remaining == 0
        end
        yield *@elements unless @elements.empty?
        @elements.clear
      end
    end
    
    private
    
    def flush
      @split = nil
      @pending = nil
      @binary_size = nil
      @remaining = 0
      @elements = []
      clear
    end
    
    # The primary performance trick is to String#split and work with that.
    def unshift_split
      unshift @split.join "\n"
      @split = nil
    end
        
    # yields redis data until no more found in buffer
    def frame
      while true
        if @binary_size
          s = read @binary_size
          break unless s
          @binary_size = nil
          yield s
        else
          line = gets
          break unless line
          case line[0..0]
          when '-'
            yield Error.new line[1..-1]
          when '+'
            yield line[1..-1]
          when ':'
            yield line[1..-1].to_i
          when '*'
            @remaining = line[1..-1].to_i
            if @remaining == -1
              yield Error.new 'timeout (nil multiblock)' 
            elsif @remaining > 1024*1024
              flush
              raise Error.new 'invalid multibulk length'
            end
          when '$'
            @binary_size = line[1..-1].to_i
            if @binary_size == -1
              @binary_size = nil
              yield nil
            elsif (@binary_size == 0 and line[1..1] != '0') or @binary_size < 0 or @binary_size > 512*1024*1024
              flush
              raise Error.new 'invalid bulk length'
            end
          else
            if @remaining > 0
              flush
              raise Error.new "expected '$', got '#{line[0]}'" 
            end
            parts = line.split(' ')
            @remaining = parts.size
            parts.each {|l| yield l}
          end
        end
      end
    end
    
    # Read a binary redis token, nil if none available
    def read length
      if @split
        if @split.first.size >= length
          result = @split.shift[0...length]
          unshift_split if @split.size == 1
          return result
        end
        unshift_split
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
      return nil unless gets
      result = @pending.join
      @pending = nil
      result
    end

    # Read a newline terminated redis token, nil if none available
    def gets
      unless @split
        @split = join.split "\n", -1
        clear
      end
      if @split.size > 1
        result = @split.shift.chomp "\n"
      else
        result = nil
      end
      unshift_split if @split.size == 1
      result
    end
    
  end
end
