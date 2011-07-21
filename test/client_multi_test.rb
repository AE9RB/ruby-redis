require File.expand_path 'test_helper', File.dirname(__FILE__)
require 'socket'

describe 'Redis Multi/Exec' do
  
  describe 'Evented Client' do
    
    it 'runs a multi with failures' do
      inner_result = full_results = error = false
      synchrony do |redis|
        redis.multi
        redis.set 'mykey', 'myfoo'
        redis.get('mykey').callback do |msg|
          inner_result = msg
        end
        redis.del 'mylist'
        redis.rpush('mylist', 1)
        redis.rpush('mylist', 2)
        redis.rpush('mylist', 'three')
        # immediate fail
        redis.badcommandforfail 
        # fail on exec
        redis.hget 'mylist', 'yeahright'
        # should still work after failures
        redis.lrange 'mylist', 0, -1
        redis.exec.callback do |results|
          full_results = results
        end.errback do |err|
          error = err
        end
        redis.synchrony.ping
      end
      flunk error if error
      inner_result.must_equal 'myfoo'
      full_results[0].must_equal 'OK'
      full_results[1].must_equal 'myfoo'
      full_results[6].must_be_kind_of Exception
      full_results[8].must_be_kind_of Array
      full_results[8].must_equal %w{1 2 three}
    end
    
    it 'fails multi because of a watch' do
      full_results = error = false
      synchrony do |redis|
        redis.del 'mylist'
        redis.watch 'mylist'
        redis.set 'mylist', 'tripped'
        redis.multi
        redis.get 'mylist'
        redis.exec.callback do |results|
          full_results = results
        end.errback do |err|
          error = true
        end
        redis.synchrony.ping
      end
      error.must_equal false
      full_results.must_equal nil
    end
    
  end


  describe 'Blocking Client' do
    
    it 'runs a multi with failures' do
      inner_result = full_results = error = false
      synchrony do |redis, r|
        redis.multi
        redis.set 'mykey', 'myfoo'
        redis.get('mykey').callback do |msg|
          inner_result = msg
        end
        redis.del 'mylist'
        redis.rpush('mylist', 1)
        redis.rpush('mylist', 2)
        redis.rpush('mylist', 'three')
        # immediate fail
        redis.badcommandforfail 
        # fail on exec
        redis.hget 'mylist', 'yeahright'
        # should still work after failures
        redis.lrange 'mylist', 0, -1
        full_results = r.exec
      end
      flunk error if error
      inner_result.must_equal 'myfoo'
      full_results[0].must_equal 'OK'
      full_results[1].must_equal 'myfoo'
      full_results[6].must_be_kind_of Exception
      full_results[8].must_be_kind_of Array
      full_results[8].must_equal %w{1 2 three}
    end
  
    it 'fails multi because of a watch' do
      full_results = false
      synchrony do |redis, r|
        redis.del 'mylist'
        redis.watch 'mylist'
        redis.set 'mylist', 'tripped'
        redis.multi
        redis.get('mylist').callback {|e| p e}
        full_results = r.exec
      end
      full_results.must_equal nil
    end

  end
  
end