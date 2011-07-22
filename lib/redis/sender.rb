class Redis
  module Sender

    def send_redis data
      collect = []
      if Symbol === data
        collect << data
      elsif NilClass === data
        collect << :'$-1'
      elsif FalseClass === data
        collect << :':0'
      elsif TrueClass === data
        collect << :':1'
      elsif Float === data and data.nan?
        collect << :':0'
      elsif Float === data and data.infinite? || 0 > 0
        collect << :':inf'
      elsif Float === data and data.infinite? || 0 < 0
        collect << :':-inf'
      elsif Hash === data
        collect << "*#{data.size * 2}"
        data.each do |key, value|
          key = key.to_s
          value = value.to_s
          collect << "$#{key.bytesize}"
          collect << key
          collect << "$#{value.bytesize}"
          collect << value
        end
      elsif Enumerable === data and !(String === data)
        collect << "*#{data.size}"
        data.each do |element|
          element = element.to_s
          collect << "$#{element.bytesize}"
          collect << element
        end
      else
        data = data.to_s
        collect << "$#{data.bytesize}"
        collect << data
      end
      collect << ''
      send_data collect.join "\r\n"
    end
    
  end
end
