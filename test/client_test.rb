require File.join(File.dirname(__FILE__), 'test_helper')
require 'socket'

describe 'Redis Client' do

  describe 'Redis Blocking Client' do

    it 'GET SET DEL EXISTS' do
      synchrony do |redis, r|
        r.set(:mykey1, 42).must_equal 'OK'
        r.get('mykey1').must_equal '42'
        r.exists('mykey1').must_equal true
        r.del('mykey1')
        r.exists('mykey1').must_equal false
      end
    end

    it 'STRLEN' do
      synchrony do |redis, r|
        r.set(:mykey1, -999).must_equal 'OK'
        r.strlen('mykey1').must_equal 4
      end
    end  
  
    it 'PING' do
      synchrony do |redis, r|
        r.ping.must_equal 'PONG'
      end
    end

    it 'BLPOP' do
      synchrony do |redis, r|
        r.del('mylist')
        r.rpush('mylist', 'whee').must_equal 1
        r.blpop('mylist', 0).must_equal ['mylist', 'whee']
        r.timeout = 5
        r.blpop('mylist', 1).must_be_nil
      end
    end
  
    it 'HMSET HGETALL' do
      synchrony do |redis, r|
        r.hmset('hasht', :A => 1, 'b' => 'two').must_equal 'OK'
        r.hgetall('hasht').must_equal 'b' => 'two', 'A' => '1'
      end
    end
  
    it 'fails when connection is closed' do
      synchrony do |redis, r|
        r.set('mykey', 'foo')
        r.get('mykey').must_equal 'foo'
        r.close_connection
        lambda{
          r.get('mykey')
        }.must_raise RuntimeError
      end
    end
    
  end

  describe 'Redis Evented Client' do
    
    it 'sends nil from BRPOPLPUSH on failure' do
      result = error = false
      synchrony do |redis|
        redis.del('mylist')
        redis.brpoplpush('mylist', 'mylist2', 1).callback do |msg|
          result = msg
        end.errback do |e|
          error = e
        end
        redis.synchrony.ping
      end
      flunk error if error
      result.must_be_nil
    end

    it 'sends array from BLPOP on success' do
      result = error = false
      synchrony do |redis|
        redis.del('mylist')
        redis.synchrony.rpush('mylist', 'lunch').must_equal 1
        redis.blpop('mylist', 0).callback do |msg|
          result = msg
        end.errback do |e|
          error = e
        end.timeout 5
        redis.synchrony.ping
      end
      flunk error if error
      result.must_equal ['mylist', 'lunch']
    end

  end
  
end