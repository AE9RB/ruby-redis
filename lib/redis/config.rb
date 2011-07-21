class Redis
  class Config < Hash
    
    INTEGERS = [:port, :timeout, :databases]
    BOOLEANS = [:daemonize]
    
    def initialize argf_or_hash

      # defaults
      self[:dir] = '.'
      self[:logfile] = 'stdout'
      self[:loglevel] = 'verbose'
      self[:daemonize] = false
      self[:pidfile] = '/var/run/redis.pid'
      self[:bind] = '127.0.0.1'
      self[:port] = 6379
      self[:timeout] = 300
      self[:databases] = 16

      this = super()
      if Hash === argf_or_hash
        super argf_or_hash
      else
        super()
        # load from ARGF or IO compatible interface
        argf_or_hash.each do |line|
          key, val = line.split ' ', 2
          self[key.downcase.gsub(/-/,'_').to_sym] = val.chomp "\n"
        end
      end

      # convert
      INTEGERS.each do |key|
        this[key] = this[key].to_i
      end

      # convert
      BOOLEANS.each do |key|
        next unless String===this[key]
        this[key] = case this[key].downcase
        when 'yes' then true
        when 'no' then false
        else nil
        end
      end
      
    end
  end
end
