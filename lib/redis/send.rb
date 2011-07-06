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
      elsif Float === data and data.nan?
        send_data ":0\r\n"
      elsif Float === data and data.infinite? || 0 > 0
        send_data ":inf\r\n"
      elsif Float === data and data.infinite? || 0 < 0
        send_data ":-inf\r\n"
      elsif Hash === data
        send_data "*#{data.size * 2}\r\n"
        data.each do |key, value|
          send_redis key
          send_redis value
        end
      elsif Enumerable === data
        send_data "*#{data.size}\r\n"
        data.each do |key|
          send_redis key
        end
      else
        if Float === data
          i = data.to_i
          data = i if i == data
        end
        data = data.to_s
        send_data "$#{data.size}\r\n"
        send_data data
        send_data "\r\n"
      end
    end
    
  end
    
end
