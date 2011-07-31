require 'eventmachine'
%w{reader sender}.each do |file|
  require File.expand_path file, File.dirname(__FILE__)
end

module Redis
  class Client < EventMachine::Connection
  
    include Sender
    
    if defined? EventMachine::Completion
      class Command < EventMachine::Completion
      end
    else
      class Command
        include EventMachine::Deferrable
      end
    end
    class Command
      # EventMachine::Deferrable older than 1.0.0.beta.4 doesn't return self
      # EventMachine::Completion doesn't return self in any version
      test = self.new
      unless self === test.callback{}
        def callback; super; self; end
        def errback; super; self; end
      end
    end

    def initialize *ignore_args
      if defined? Hiredis and defined? Hiredis::Reader
        @reader = Hiredis::Reader.new
      else
        @reader = Reader.new
      end
      @queue = []
      @multi = nil
      @pubsub_callback = proc{}
    end
  
    def unbind
      until @queue.empty?
        @queue.shift.fail RuntimeError.new 'connection closed'
      end
    end
  
    # This is simple and fast but doesn't test for programming errors.
    # Don't send non-pubsub commands while subscribed and you're fine.
    # Subclass Client and/or create a defensive layer if you need to.
    def on_pubsub &block
      @pubsub_callback = block
    end
  
    def receive_data data
      @reader.feed data
      until (
        begin
          data = @reader.gets
        rescue Exception => e
          raise e if Interrupt === e
          @queue.shift.fail e unless @queue.empty?
          close_connection
          data = false
        end
      ) == false
        deferrable = @queue.shift
        if deferrable
          if Exception === data
            deferrable.fail data
          else
            deferrable.succeed data
          end
        else
          @pubsub_callback.call data
        end
      end
    end
    
    def method_missing method, *args, &block
      if @multi and ![:multi, :exec].include? method
        for_queue = new_command true, false, method, *args
        command = new_command false, true, method
        callback_multi = @multi
        for_queue.callback do |status|
          callback_multi << command
        end
        for_queue.errback do |err|
          callback_multi << err
          command.fail err
        end
      else
        command = new_command true, true, method, *args
      end
      command.callback &block if block
      command
    end
    
    def in_multi?
      !!@multi
    end
    
    def multi *args
      @multi ||= []
      method_missing :multi, *args
    end
    
    def exec *args
      redis_exec = method_missing :exec, *args
      callback_multi = @multi
      @multi = nil
      redis_exec.callback do |results|
        if results
          normalized_results = []
          callback_multi.each do |command|
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
    
    # Some data is best transformed into a Ruby type.  You can set up global
    # transforms here that are automatically attached to command callbacks.
    #   Redis::Client.transforms[:mycustom1] = Redis::Client.transforms[:exists] # boolean
    #   Redis::Client.transforms[:mycustom2] = proc { |data| MyType.new data }
    #   Redis::Client.transforms.delete :hgetall # if you prefer the array
    def self.transforms
      @@transforms ||= lambda {
        boolean = lambda { |tf| tf[0] == 1 ? true : false }
        hash = lambda { |hash| Hash[*hash] }
        pubsub = lambda { |msg| lambda { msg } }
        {
          #pubsub
          :subscribe => pubsub,
          :psubscribe => pubsub,
          :unsubscribe => pubsub,
          :punsubscribe => pubsub,
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
    
    private

    def new_command do_send, do_transform, method, *args
      command = Command.new
      if do_send
        send_redis args.reduce([method]){ |arr, arg|
          if Hash === arg
            arr += arg.to_a.flatten 1
          else
            arr << arg
          end
        }
        @queue.push command
      end
      if do_transform
        if transform = self.class.transforms[method]
          command.callback do |data|
            result = transform.call data
            if Proc === result
              command.succeed nil
              @pubsub_callback.call result.call
            else
              command.succeed result
            end
          end
        end
      end
      command
    end

  end  
end
