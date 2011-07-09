require File.join(File.dirname(__FILE__), 'test_helper')
require 'socket'

describe 'Redis Client' do

  before do
    @redis = EventMachine.connect '127.0.0.1', 6379, Redis
    @r = @redis.synchrony
  end
  
  after do
    @redis.close_connection
  end
  
  describe 'Redis Blocking Client' do

    it 'GET SET DEL EXISTS' do
      @r.set(:mykey1, 42).must_equal 'OK'
      @r.get('mykey1').must_equal '42'
      @r.exists('mykey1').must_equal true
      @r.del('mykey1')
      @r.exists('mykey1').must_equal false
    end

    it 'STRLEN' do
      @r.set(:mykey1, -999).must_equal 'OK'
      @r.strlen('mykey1').must_equal 4
    end  
  
    it 'PING' do
      @r.ping.must_equal 'PONG'
    end

    it 'BLPOP' do
      @r.del('mylist')
      @r.rpush('mylist', 'whee').must_equal 1
      @r.blpop('mylist', 0).must_equal ['mylist', 'whee']
      @r.timeout = 5
      @r.blpop('mylist', 1).must_be_nil
    end
  
    it 'HMSET HGETALL' do
      @r.hmset('hasht', :A => 1, 'b' => 'two').must_equal 'OK'
      @r.hgetall('hasht').must_equal 'b' => 'two', 'A' => '1'
    end
  
    it 'fails when connection is closed' do
      @r.set('mykey', 'foo')
      @r.get('mykey').must_equal 'foo'
      @r.close_connection
      lambda{
        @r.get('mykey')
      }.must_raise RuntimeError
    end
    
  end

  describe 'Redis Evented Client' do
    
    it 'sends nil from BRPOPLPUSH on failure' do
      result = error = nil
      @r.del('mylist')
      @redis.brpoplpush('mylist', 'mylist2', 1).callback do |msg|
        result = msg
      end.errback do |e|
        error = e
      end
      @r.ping
      flunk error if error
      result.must_be_nil
    end

    it 'sends array from BLPOP on success' do
      result = error = nil
      @r.del('mylist')
      @r.rpush('mylist', 'lunch').must_equal 1
      @redis.blpop('mylist', 0).callback do |msg|
        result = msg
      end.errback do |e|
        error = e
      end.timeout 5
      @r.ping
      flunk error if error
      result.must_equal ['mylist', 'lunch']
    end

  end
  
end