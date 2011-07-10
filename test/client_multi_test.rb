require File.join(File.dirname(__FILE__), 'test_helper')
require 'socket'

describe 'Redis Multi/Exec' do
  
  describe 'Evented Client' do
    
    it 'runs a multi with failures' do
      inner_result = full_results = error = false
      synchrony do |redis|
        redis.multi_exec do |multi|
          multi.set 'mykey', 'myfoo'
          multi.get('mykey').callback do |msg|
            inner_result = msg
          end
          multi.del 'mylist'
          multi.rpush('mylist', 1)
          multi.rpush('mylist', 2)
          multi.rpush('mylist', 'three')
          # immediate fail
          multi.badcommandforfail 
          # fail on exec
          multi.hget 'mylist', 'yeahright'
          # should still work after failures
          multi.lrange 'mylist', 0, -1
        end.callback do |results|
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
        redis.multi_exec do |multi|
          multi.get 'mylist'
        end.callback do |results|
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
        full_results = r.multi_exec do |multi|
          multi.set 'mykey', 'myfoo'
          multi.get('mykey').callback do |msg|
            inner_result = msg
          end
          multi.del 'mylist'
          multi.rpush('mylist', 1)
          multi.rpush('mylist', 2)
          multi.rpush('mylist', 'three')
          # immediate fail
          multi.badcommandforfail 
          # fail on exec
          multi.hget 'mylist', 'yeahright'
          # should still work after failures
          multi.lrange 'mylist', 0, -1
        end
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
        full_results = r.multi_exec do |multi|
          multi.get('mylist').callback {|e| p e}
        end
      end
      full_results.must_equal nil
    end

  end
  
end