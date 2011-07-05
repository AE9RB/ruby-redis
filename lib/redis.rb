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
  
  class Deferrable
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
        if data.size == 1 and StandardError === data[0]
          deferrable.fail data[0].message
        else
          deferrable.succeed *data
        end
      end
    end
  rescue StandardError => e
    @queue.pop do |deferrable| 
      deferrable.fail e.message
    end
    close_connection
  end
  
  def method_missing method, *args, &block
    deferrable = Deferrable.new
    deferrable.errback do |msg|
      unless msg
        deferrable.fail 'command timeout'
        close_connection 
      end
    end
    deferrable.callback &block if block_given?
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
  
end

