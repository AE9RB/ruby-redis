require 'set'

class Redis
  
  #TODO add and delete should work on @keys instead of clearing
  class ZSet < Set
    def initialize(*args, &block)
	    @keys = nil
	    @keys_reverse = nil
	    super
	  end
	  
	  def add(o, s = 0.0)
      @hash[o] = s
	    @keys = nil
	    @keys_reverse = nil
      self
    end
	  alias << add

	  def delete(o)
	    @keys = nil
	    @keys_reverse = nil
	    @hash.delete(o)
	    self
	  end
	  
	  def score(o)
	    @hash[o]
    end
    
    def range reverse, start ,stop, withscores
      array = reverse ? to_a_reverse : to_a
      start = start.to_redis_i
      stop = stop.to_redis_i
      start = 0 if start < -size
      return array[start..stop].flatten(1) if withscores
      (array[start..stop]||[]).collect{|i|i.first}
    end
    
    def range_by_score reverse, min, max, *args
      withscores = offset = count = nil
      until args.empty?
        case args.shift.upcase
        when 'LIMIT'
          offset = args.shift.to_i
          count = args.shift.to_i
        when 'WITHSCORES'
          withscores = true
        else
          raise 'bad arguments'
        end
      end
      result = []
      min_exclusive = false
      if min[0] == '('
        min_exclusive = true
        min = min[1..-1]
      end
      min = min.to_redis_f
      max_exclusive = false
      if max[0] == '('
        max_exclusive = true
        max = max[1..-1]
      end
      max = max.to_redis_f
      if reverse
        x = min; min = max; max = x
      end
      (reverse ? to_a_reverse : to_a).each do |member, score|
        next if min > score or (min_exclusive and min >= score)
        next if max < score or (max_exclusive and max <= score)
        if offset
          offset -= 1
          next unless offset < 0
          offset = nil
        end
        result << member
        result << score if withscores
        if count
          count -= 1
          break if count == 0
        end
      end
      result
    end

	  def clear
	    @keys = nil
	    @keys_reverse = nil
	    super
	  end

	  def replace(enum)
	    @keys = nil
	    @keys_reverse = nil
	    super
	  end

	  def delete_if
      block_given? or return enum_for(__method__)
	    n = @hash.size
	    super
	    @keys_reverse = @keys = nil if @hash.size != n
	    self
	  end

	  def keep_if
	    block_given? or return enum_for(__method__)
	    n = @hash.size
	    super
	    @keys_reverse = @keys = nil if @hash.size != n
	    self
	  end

	  def merge(enum)
	    @keys = nil
	    @keys_reverse = nil
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
	  
	  def to_a_reverse
	    unless @keys_reverse
	      @keys_reverse = to_a.reverse
      end
	    @keys_reverse
    end
  end
  
  module ZSets

    def redis_ZADD key, score, member
      record = (@database[key] ||= ZSet.new)
      result = !record.include?(member)
      record.add member, score.to_redis_f
      result
    end
    
    def redis_ZINCRBY key, increment, member
      record = (@database[key] ||= ZSet.new)
      increment = increment.to_redis_f
      if record.include?(member)
        score = record.score(member) + increment
      else
        score = increment
      end
      record.add member, score
      score
    end
    
    def redis_ZRANK key, member
      record = (@database[key] || ZSet.new).to_a
      record.index {|i| i[0]==member}
    end
    
    def redis_ZREM key, member
      record = @database[key] || []
      return false unless record.include? member
      record.delete member
      @database.delete key if record.empty?
      return true
    end
    
    def redis_ZSCORE key, member
      (@database[key] || ZSet.new).score member
    end
    
    def redis_ZREVRANK key, member
      record = (@database[key] || ZSet.new).to_a_reverse
      record.index {|i| i[0]==member}
    end
    
    def redis_ZCARD key
      (@database[key] || []).size
    end
    
    def redis_ZCOUNT key, min, max
      record = @database[key] || ZSet.new
      record.range_by_score(true, max, min).size
    end

    def redis_ZREVRANGEBYSCORE key, min, max, *args
      record = @database[key] || ZSet.new
      record.range_by_score true, min, max, *args
    end
    
    def redis_ZRANGEBYSCORE key, min, max, *args
      record = @database[key] || ZSet.new
      record.range_by_score false, min, max, *args
    end
  
    def redis_ZRANGE key, start ,stop, withscores = false
      record = @database[key] || ZSet.new
      record.range false, start ,stop, withscores
    end
  
    def redis_ZREVRANGE key, start ,stop, withscores = false
      record = @database[key] || ZSet.new
      record.range true, start ,stop, withscores
    end
    
  end
end
