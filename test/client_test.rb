require File.join(File.dirname(__FILE__), 'test_helper')
require 'socket'

describe 'Redis EventMachine Client' do
  
  before do
    @r = BlockingRedis.new TCPSocket.new("127.0.0.1", 6379)
  end
  
  it 'PING responds with PONG' do
    @r.ping.must_equal ['PONG']
  end
  
  it 'gets and sets strings' do
    @r.set(:everything, 42).must_equal ['OK']
    @r.get('everything').must_equal ['42']
  end
  
  it 'gets and sets hashes' do
    @r.hmset('hasht', :A => 1, 'b' => 'two').must_equal ['OK']
    @r.hgetall('hasht').must_equal ["A", "1", "b", "two"]
  end

end