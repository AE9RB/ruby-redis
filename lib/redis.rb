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
require_relative 'redis/synchrony'

class Redis
  
  include Send
  
  class Command
    include EventMachine::Deferrable
    def initialize connection
      @connection = connection
      self.errback do |msg|
        # game over on timeout
        @connection.close_connection unless msg
      end
    end
    def callback; super; self; end
    def errback; super; self; end
    def timeout *args; super; self; end
  end
  
  # Yielded by multi_exec to proxy and collect commands
  class Multi < Command
    include Enumerable
    def initialize *args
      super
      @commands = []
    end
    def each
      @commands.each {|x|yield x}
    end
    def size
      @commands.size
    end
    def method_missing method, *args, &block
      command = @connection.send method, *args, &block
      proxy = Command.new @connection
      command.callback do |status|
        @commands << proxy
      end
      command.errback do |err|
        @commands << err
        proxy.fail err
      end
      proxy
    end
  end
  
  # Wrap around multi and exec.  Leaves the raw calls
  # to multi and exec open for custom implementations.
  def multi_exec
    self.multi.errback do
      # This usually happens in the case of a programming error.
      # Sometimes it is called when the connection breaks.
      self.close_connection
    end
    yield redis_multi = Multi.new(self)
    redis_exec = self.exec
    redis_exec.callback do |results|
      # Normalized results include syntax errors and original references.
      # Command callbacks are meant to run before exec callbacks.
      if results == nil
        redis_exec.succeed nil
      else
        normalized_results = []
        redis_multi.each do |command|
          if Exception === command
            normalized_results << command
          else
            result = results.shift
            normalized_results << result
            if Exception === result
              command.fail result
            else
              command.succeed result
            end
          end
        end
        redis_exec.succeed normalized_results
      end
    end
  end
  
  def initialize options={}
    if options[:hiredis]
      @buftok = HiredisReader.new
    else
      @buftok = BufferedTokenizer.new
    end
    @queue = []
  end
  
  def unbind
    @queue.each { |d| d.fail RuntimeError.new 'connection closed' }
    @queue = []
  end
  
  def receive_data data
    @buftok.extract(data) do |data|
      if Exception === data
        @queue.shift.fail data
      else
        @queue.shift.succeed data
      end
    end
  rescue Exception => e
    @queue.shift.fail e
    close_connection
  end
  
  def method_missing method, *args, &block
    deferrable = Command.new self
    transform = self.class.transforms[method.downcase]
    if transform and Proc === transform
      deferrable.callback do |data|
        begin
          deferrable.succeed transform.call data
        rescue Exception => e
          deferrable.fail e
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

  # Some data is best transformed into a Ruby type.  You can set up global
  # transforms here that are automatically attached to command callbacks.
  #   Redis.transforms[:mycustom1] = Redis.transforms[:exists] # boolean
  #   Redis.transforms[:mycustom2] = proc { |data| MyType.new data }
  def self.transforms
    @@transforms ||= lambda {
      boolean = lambda { |tf| tf[0] == 1 ? true : false }
      hash = lambda { |hash| Hash[*hash] }
      {
        #keys
        :exists => boolean,
        :expire => boolean,
        :expireat => boolean,
        :move => boolean,
        :persist => boolean,
        :renamenx => boolean,
        #strings
        :msetnx => boolean,
        :setnx => boolean,
        #hashes
        :hexists => boolean,
        :hgetall => hash,
        :hset => boolean,
        :hsetnx => boolean,
        #sets
        :sismember => boolean,
        :smove => boolean,
        :srem => boolean,
        #zsets
        :zrem => boolean,
      }
    }.call
  end

  
end

