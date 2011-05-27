require_relative 'protocol'
require_relative 'commands'

require 'eventmachine'

class Redis
  class Server < EventMachine::Connection
    
    include Protocol
    include Commands
    
    def initialize options={}
      super
      @options = options
    end
    
  end
end


if __FILE__ == $0
require_relative 'test'

end
