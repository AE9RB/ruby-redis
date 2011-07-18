require_relative '../lib/redis/fibers'

def run_test_on_fiber
  
  Redis.fiber(Redis.connect '127.0.0.1', 6379 ) do |conn| 
    conn.attach Cool.io::Loop.default
    yield conn
    connection.close
  end
  Cool.io::Loop.default.run

end
