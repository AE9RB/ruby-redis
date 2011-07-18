require File.expand_path '../redis', File.dirname(__FILE__)

class Redis
  
    # This is almost as fast as hiredis/reader plus it supports servers
  class Reader < Array

    # Minimize the amount of memory copying. The primary
    # performance trick is to String#split and work with that.

    #TODO configurable limits
    #TODO max buffer size based on limits
    
    def initialize
      super()
      flush
    end
    
    def feed data
      unshift_split if @split
      push data
    end
    
    # def gets
    # end
    # 
    def gets #data, &block # keep block param for rubinius
      frame do |str|
        @elements << str
        if @remaining > 0
          @remaining -= 1
          if @remaining == 0 and !@stack.empty?
            elements = @elements
            @elements, @remaining = @stack.pop
            @elements << elements
            @remaining -= 1
          end
          next unless @remaining == 0
          @completed << @elements
        elsif @remaining < 0
          @completed << nil
        elsif !@elements.empty?
          @completed << @elements[0]
        end
        @elements = []
        @remaining = 0
      end
      return false if @completed.empty?
      @completed.shift
    end
    
    private
    
    def flush
      @split = nil
      @pending = nil
      @binary_size = nil
      @remaining = 0
      @elements = []
      @stack = []
      @completed = []
      clear
    end
    
    def unshift_split
      unshift @split.join "\n"
      @split = nil
    end
        
    # yields redis data until no more found in buffer
    def frame
      while true
        if @binary_size
          s = read_binary @binary_size
          break unless s
          @binary_size = nil
          yield s
        else
          line = read_line
          break unless line
          case line[0..0]
          when '-'
            yield RuntimeError.new line[1..-1]
          when '+'
            yield line[1..-1]
          when ':'
            yield line[1..-1].to_i
          when '*'
            prev_remaining = @remaining
            @remaining = line[1..-1].to_i
            if @remaining == -1
              yield nil
            elsif @remaining > 1024*1024
              flush
              raise 'invalid multibulk length'
            elsif prev_remaining > 0
              @stack << [@elements, prev_remaining]
              @elements = []
            end
          when '$'
            @binary_size = line[1..-1].to_i
            if @binary_size == -1
              @binary_size = nil
              yield nil
            elsif (@binary_size == 0 and line[1..1] != '0') or @binary_size < 0 or @binary_size > 512*1024*1024
              flush
              raise 'invalid bulk length'
            end
          else
            if @remaining > 0
              flush
              raise "expected '$', got '#{line[0].chr}'" 
            end
            parts = line.split(' ')
            @remaining = parts.size
            parts.each {|l| yield l}
          end
        end
      end
    end
    
    # Read a binary redis token, nil if none available
    def read_binary length
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
      return nil unless read_line
      result = @pending.join
      @pending = nil
      result
    end

    # Read a newline terminated redis token, nil if none available
    def read_line
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
