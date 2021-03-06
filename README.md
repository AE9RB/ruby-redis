This project was started because I needed an authenticating and routable
proxy for Redis.  The main feature is a high performance, eventable, pure Ruby
implementation of the complete Redis wire protocol using the same interface as
hiredis/reader.

### Ruby Gem

    # Best with Ruby 1.9.2; works with 1.8.7, JRuby, and Rubinius.
    gem install ruby-redis
    # Runs a server that looks and feels like the C redis-server
    ruby-redis

### Client example

    require 'redis'
    EventMachine.run {
      redis = EventMachine.connect '127.0.0.1', 6379, Redis::Client
      # Subscribe and publish messages will call here
      redis.on_pubsub do |message|
        # case message[0]
        # when 'psubscribe' ...
      end
      # All commands implemented uniformly with method_missing
      # Returns instance of Redis::Command < EventMachine::Deferrable 
      # Pipelining is implicit
      redis.set :pi, 3.14159
      redis.get('pi') do |result|
        p result
      end
      redis.blpop('mylist', 1).callback do |result|
        p result
        EM.stop
      end.errback do |e|
        EM.stop
        raise e
      end
    }


### Using hiredis/reader (only affects clients)

    # require it before you connect
    require 'hiredis/reader'

### Fibers example (compatible with em-synchrony)

    require 'redis/synchrony'
    Redis.synchrony {
      # Be sure to pipeline commands when you can
      redis = EventMachine.connect '127.0.0.1', 6379, Redis::Client
      # synchronized requests will return result or raise exception
      sync = redis.synchrony
      # repeat transaction until success
      reply = check = nil
      until reply
        redis.watch 'mykey'
        x = sync.get('mykey').to_i
        redis.multi
        redis.set 'mykey', x + 1
        redis.badcmd
        redis.get('mykey') {|result| check=result}
        reply = sync.exec
      end
      redis.close
      EM.stop
      p reply, check # ["OK", #<RuntimeError>, "4"], "4"
    }


### Ruby to Redis type conversions

          String === Status reply
    RuntimeError === Error reply
          String === Bulk reply
         Integer === Integer reply
           Array === Multi-bulk reply
            Hash === Multi-bulk reply to hgetall
        NilClass === Nil element or nil multi-bulk
       TrueClass === :1
      FalseClass === :0
