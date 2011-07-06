require File.join(File.dirname(__FILE__), 'test_helper')
require 'socket'

describe 'Redis EventMachine Client' do
  
  before do
    @r = Redis::Client.new TCPSocket.new("127.0.0.1", 6379)
  end
  
  after do
    @r.close_connection
  end
  
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
    lambda{
      @r.timeout = 3
      begin
        @r.blpop('mylist', 1)
      rescue Exception => e
        e.message.must_match 'multiblock'
        raise e
      end
    }.must_raise RuntimeError
  end
  
  it 'hash basics' do
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