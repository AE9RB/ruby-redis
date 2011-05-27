class Redis
  module Protocol
  
    def initialize *args
      @binary_size = nil
      @remainder = ''
      @multi_bulk = 0
      @command = nil
      @arguments = []
    end
  
    # receive_frame argument block ?
    def build_command(str)
      if @command
        @arguments << str
      else
        @command = str
        #TODO detect telnet shortcuts
      end
      if @multi_bulk > 0
        @multi_bulk -= 1
        return unless @multi_bulk == 0
      end
      run_command unless @command.empty?
      @command = nil
      @arguments = []
    end
  
    def receive_data(data)
      #TODO limit data + remainder
      # Voodoo with the -1
      entities = data.split "\n", -1
      entities[0] = @remainder + entities[0]
      @remainder = entities.pop
      bin = [] #TODO class RedisString
      entities.each do |e|
        if @binary_size
          # Two paths for performance optimization
          if e.size >= @binary_size and bin.empty?
            build_command e[0...@binary_size]
            @binary_size = nil
          else
            bin << e
            bin_size = bin.reduce(0){|x,y|x+y.size+1}-1
            if bin_size >= @binary_size
              build_command bin.join("\n")[0...@binary_size]
              @binary_size = nil
              bin = []
            end
          end
        else
          case e[0]
          when '*'
            @multi_bulk = e[1..-1].to_i
          when '$'
            @binary_size = e[1..-1].to_i
            raise "TODO" if @binary_size == -1 # spec says should be nil
          else
            build_command e.chomp
          end
        end
      end
      @remainder += bin.reduce(''){|x,y|x+y+"\n"} #TODO class RedisString
    end

  end
end

if __FILE__ == $0
require_relative 'test'

end
