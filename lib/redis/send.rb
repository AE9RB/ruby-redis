require File.expand_path '../redis', File.dirname(__FILE__)

class Redis
  
  module Send
    
    def send_redis data
      collect = []
      if nil == data
        collect << "$-1\r\n"
      elsif false == data
        collect << ":0\r\n"
      elsif true == data
        collect << ":1\r\n"
      elsif Float === data and data.nan?
        collect << ":0\r\n"
      elsif Float === data and data.infinite? || 0 > 0
        collect << ":inf\r\n"
      elsif Float === data and data.infinite? || 0 < 0
        collect << ":-inf\r\n"
      elsif Hash === data
        collect << "*#{data.size * 2}\r\n"
        data.each do |key, value|
          key = key.to_s
          value = value.to_s
          collect << "$#{key.bytesize}\r\n"
          collect << key
          collect << "\r\n$#{value.bytesize}\r\n"
          collect << value
          collect << "\r\n"
        end
      elsif Enumerable === data and !(String === data)
        collect << "*#{data.size}\r\n"
        data.each do |element|
          element = element.to_s
          collect << "$#{element.bytesize}\r\n"
          collect << element
          collect << "\r\n"
        end
      else
        data = data.to_s
        collect << "$#{data.bytesize}\r\n"
        collect << data
        collect << "\r\n"
      end
      send_data collect.join
    end
    
  end
    
end
