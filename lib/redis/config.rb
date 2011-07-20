class Redis
  
  class Config < Hash
    
    INTEGERS = [:port, :timeout, :databases]
    BOOLEANS = [:daemonize]
    
    def initialize argf
      super()

      # defaults
      self[:dir] = '.'
      self[:logfile] = 'stdout'
      self[:daemonize] = false
      self[:port] = 6379
      self[:pidfile] = "/var/run/redis.pid"
      self[:databases] = 16

      # load from ARGF or IO compatible interface
      argf.each do |line|
        key, val = line.split ' ', 2
        self[key.downcase.gsub(/-/,'_').to_sym] = val.chomp "\n"
      end

      # convert
      INTEGERS.each do |key|
        self[key] = self[key].to_i
      end

      # convert
      BOOLEANS.each do |key|
        next unless String===self[key]
        self[key] = case self[key].downcase
        when 'yes' then true
        when 'no' then false
        else nil
        end
      end
      
    end
    
  end
    
end
