require 'set'

class Redis
  
  class ZSet < Set
    def initialize(*args, &block)
	    @keys = nil
	    super
	  end
	  
	  def add(o, v = 0.0)
      @hash[o] = v
	    @keys = nil
      self
    end
	  alias << add

	  def clear
	    @keys = nil
	    super
	  end

	  def replace(enum)
	    @keys = nil
	    super
	  end

	  def delete(o)
	    @keys = nil
	    @hash.delete(o)
	    self
	  end

	  def delete_if
      block_given? or return enum_for(__method__)
	    n = @hash.size
	    super
	    @keys = nil if @hash.size != n
	    self
	  end

	  def keep_if
	    block_given? or return enum_for(__method__)
	    n = @hash.size
	    super
	    @keys = nil if @hash.size != n
	    self
	  end

	  def merge(enum)
	    @keys = nil
	    super
	  end

	  def each
	    block_given? or return enum_for(__method__)
	    to_a.each { |o| yield(o) }
	    self
	  end

	  def to_a
	    unless @keys
  	    (@keys = @hash.to_a).sort! do |a, b|
  	      a.reverse <=> b.reverse
	      end
	    end
	    @keys
	  end
  end
  
  module ZSets
    
    def redis_ZADD key, score, member
      record = (@database[key] ||= ZSet.new)
      result = !record.include?(member)
      record.add member, score.to_f
      Redis.logger.warn "#{member}, #{score.to_f}"
      result
    end
    
    def redis_ZCARD key
      (@database[key] || []).size
    end
  
    def redis_ZRANGE key, start ,stop, withscores = false
      record = (@database[key] || ZSet.new).to_a
      start = start.to_redis_i
      stop = stop.to_redis_i
      start = 0 if start < -record.size
      return record[start..stop].flatten(1) if withscores
      (record[start..stop]||[]).collect{|i|i.first}
    end
  
    def redis_ZREVRANGE key, start ,stop, withscores = false
      record = (@database[key] || ZSet.new).to_a.reverse
      start = start.to_redis_i
      stop = stop.to_redis_i
      start = 0 if start < -record.size
      return record[start..stop].flatten(1) if withscores
      (record[start..stop]||[]).collect{|i|i.first}
    end
    
  end
end
