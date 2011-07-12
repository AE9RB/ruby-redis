require File.join(File.dirname(__FILE__), 'test_helper')
require 'socket'

describe 'Redis Subscribe' do
  
  it 'handles subscriptions' do
    responses = []
    messages = []
    synchrony do |redis|
      redis.pubsub_callback do |message|
        messages << message
      end
      
      redis.subscribe.callback do |response|
        responses << response
      end.errback do |e|
        responses << e
      end

      responses << redis.synchrony.psubscribe('foo*')

      redis.subscribe('bat').callback do |response|
        responses << response
      end.errback do |e|
        responses << e
      end

      redis.punsubscribe.callback do |response|
        responses << response
      end.errback do |e|
        responses << e
      end

      responses << redis.synchrony.unsubscribe
      responses << redis.synchrony.ping
      
    end
    
    responses[0].must_be_kind_of Exception
    1.upto(4) {|i| responses[i].must_be_nil}
    responses[5].must_equal 'PONG'
    
    messages[0].must_equal ["psubscribe", "foo*", 1]
    messages[1].must_equal ["subscribe", "bat", 2]
    messages[2].must_equal ["punsubscribe", "foo*", 1]
    messages[3].must_equal ["unsubscribe", "bat", 0]
    
  end
  

  
end