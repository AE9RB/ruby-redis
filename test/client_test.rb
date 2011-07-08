require File.join(File.dirname(__FILE__), 'test_helper')
require 'socket'

describe 'Redis Client' do

  before do
    @r = Redis::Client.new TCPSocket.new('127.0.0.1', 6379)
  end
  
  after do
    @r.close_connection
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
    
    def emrun &block
      thread = Thread.current
      Thread.new do
        EM.run do
          yield EventMachine.connect('127.0.0.1', 6379, Redis), thread
        end
      end
      sleep
    end

    it 'sends nil from BRPOPLPUSH on failure' do
      @r.del('mylist')
      result = error = nil
      emrun do |redis, thread|
        redis.brpoplpush('mylist', 'mylist2', 1).callback do |msg|
          result = msg
          thread.wakeup
        end.errback do |e|
          error = e
          thread.wakeup
        end.timeout 5
      end
      flunk error if error
      result.must_be_nil
    end

    it 'sends array from BLPOP on success' do
      @r.del('mylist')
      @r.rpush('mylist', 'lunch').must_equal 1
      result = error = nil
      emrun do |redis, thread|
        redis.blpop('mylist', 0).callback do |msg|
          result = msg
          thread.wakeup
        end.errback do |e|
          error = e
          thread.wakeup
        end.timeout 5
      end
      flunk error if error
      result.must_equal ['mylist', 'lunch']
    end

  end
  
end