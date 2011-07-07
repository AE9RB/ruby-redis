# for Ruby older than 1.9
unless Kernel.respond_to?(:require_relative)
  module Kernel
    def require_relative(path)
      require File.join(File.dirname(caller[0]), path.to_str)
    end
  end
end

require 'eventmachine'
class Redis < EventMachine::Connection ; end

require_relative 'redis/version'
require_relative 'redis/buftok'
require_relative 'redis/send'

class Redis
  
  include Send
  
  class Command
    include EventMachine::Deferrable
    def callback; super; self; end
    def errback; super; self; end
    def timeout *args; super; self; end
  end

  def initialize
    @buftok = BufferedTokenizer.new
    @queue = EventMachine::Queue.new
  end
  
  def unbind
    @queue.size.times do
      @queue.pop do |deferrable| 
        deferrable.fail 'connection closed'
      end
    end
  end
  
  def receive_data data
    @buftok.extract(data) do |*data|
      @queue.pop do |deferrable|
        if data.size == 1 and Exception === data[0] and !(MultiBlockNil === data[0])
          deferrable.fail data[0].message
        else
          deferrable.succeed *data
        end
      end
    end
  rescue Exception => e
    @queue.pop do |deferrable| 
      deferrable.fail e.message
    end
    close_connection
  end
  
  def method_missing method, *args, &block
    deferrable = Command.new
    deferrable.errback do |msg|
      unless msg
        deferrable.fail 'command timeout'
        close_connection 
      end
    end
    transform = self.class.transforms[method.downcase]
    if transform and Proc === transform
      deferrable.callback do |*data|
        begin
          deferrable.succeed transform.call *data
        rescue Exception => e
          deferrable.fail e.message
        end
      end
    end
    deferrable.callback &block if block
    @queue.push deferrable
    send_redis args.reduce([method]){ |arr, arg|
      if Hash === arg
        arr += arg.to_a.flatten 1
      else
        arr << arg
      end
    }
    deferrable
  end

  # All redis commands with a single return value are defined here.
  # Strings and integers are included for the blocking implementation.
  # The default processing is for a multiblock; so new/custom commands
  # will always send an array until you configure them.  ex.
  #   Redis.transforms[:mycustom1] = Redis.transforms[:del] # integer
  #   Redis.transforms[:mycustom2] = proc { |data| MyType.new data }
  def self.transforms
    @@transforms ||= lambda {
      status = string = integer = true
      boolean = lambda { |tf| tf == 1 ? true : false }
      hash = lambda { |*hash| Hash[*hash] }
      bpop =  lambda { |*data| (data.size == 1 and MultiBlockNil === data[0]) ? nil : data }
      bpoppush =  lambda { |data| MultiBlockNil === data ? nil : data }
      {
        #keys
        :del => integer,
        :exists => boolean,
        :expire => boolean,
        :expireat => boolean,
        :move => boolean,
        :persist => boolean,
        :randomkey => string,
        :rename => status,
        :renamenx => boolean,
        :ttl => integer,
        :type => status,
        #strings
        :append => integer,
        :decr => integer,
        :decrby => integer,
        :get => string,
        :getbit => integer,
        :getrange => string,
        :getset => string,
        :incr => integer,
        :incrby => integer,
        :mset => status,
        :msetnx => boolean,
        :set => status,
        :setbit => integer,
        :setex => status,
        :setnx => boolean,
        :setrange => integer,
        :strlen => integer,
        #hashes
        :hdel => integer,
        :hexists => boolean,
        :hgetall => hash,
        :hincrby => integer,
        :hlen => integer,
        :hmset => status,
        :hset => boolean,
        :hsetnx => boolean,
        #lists
        :blpop => bpop,
        :brpop => bpop,
        :brpoplpush => bpoppush,
        :lindex => string,
        :linsert => integer,
        :llen => integer,
        :lpop => string,
        :lpush => integer,
        :lpushx => integer,
        :lrem => integer,
        :lset => status,
        :ltrim => status,
        :rpop => string,
        :rpoplpush => string,
        :rpush => integer,
        :rpushx => integer,
        #sets
        :sadd => integer,
        :scard => integer,
        :sdiffstore => integer,
        :sinterstore => integer,
        :sismember => boolean,
        :smove => boolean,
        :spop => string,
        :srandmember => string,
        :srem => boolean,
        :sunionstore => integer,
        #zsets
        :zadd => integer,
        :zcard => integer,
        :zcount => integer,
        :zincrby => string,
        :zinterstore => integer,
        :zrank => integer,
        :zrem => boolean,
        :zremrangebyrank => integer,
        :zremrangebyscore => integer,
        :zrevrank => integer,
        :zscore => string,
        :zunionstore => integer,
        #pubsub
        :publish => integer,
        #transactions
        :discard => status,
        :multi => status,
        :unwatch => status,
        :watch => status,
        #connection
        :auth => status,
        :echo => string,
        :ping => status,
        :quit => status,
        :select => status,
        #server
        :bgrewriteaof => status,
        :bgsave => status,
        :config => string,
        :dbsize => integer,
        :flushall => status,
        :flushdb => status,
        :info => string,
        :lastsave => integer,
        :shutdown => status,
        :slaveof => status,
      }
    }.call
  end

  
end

