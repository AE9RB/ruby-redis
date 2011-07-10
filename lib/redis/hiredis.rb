require_relative '../redis'

class Redis
  
  # hiredis doesn't support server protocol, but it can be a direct
  # replacement for BufferedTokenizer and will speed up the client.

  @@hiredis_default = false

  def self.hiredis_default= value
    @@hiredis_default = value
  end
  
  def self.hiredis_default
    require 'hiredis/reader'
    @@hiredis_default = true
  end
  
  class HiredisReader
    def initialize
      require 'hiredis/reader'
      @reader = ::Hiredis::Reader.new
    end
    def extract data
      @reader.feed data
      until (reply = @reader.gets) == false
        yield reply
      end
    end
  end

end