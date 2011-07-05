require File.join(File.dirname(__FILE__), '../redis')

class Redis
  
  module Send
    
    def send_redis data
      if nil == data
        send_data "$-1\r\n"
      elsif false == data
        send_data ":0\r\n"
      elsif true == data
        send_data ":1\r\n"
      elsif Array === data
        send_data "*#{data.size}\r\n"
        data.each do |key|
          send_redis key
        end
      elsif Hash === data
        send_data "*#{data.size * 2}\r\n"
        data.each do |key, value|
          send_redis key
          send_redis value
        end
      elsif Float === data and data.infinite? || 0 > 0
        send_redis '+inf'
      elsif Float === data and data.infinite? || 0 < 0
        send_redis '-inf'
      else
        data = data.to_s
        send_data "$#{data.size}\r\n"
        send_data data
        send_data "\r\n"
      end
    end
    
  end
    
end
