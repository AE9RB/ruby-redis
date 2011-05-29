class Redis
  
  VERSION = '0.0.0.pre'
  
  def self.databases
    @@databases ||= [{}]
  end
    
end

