module Phonelib
  # module provides extended data methods for parsed phone
  module PhoneExtendedData
    # Returns geo name of parsed phone number or nil if number is invalid or
    # there is no geo name specified in db for this number
    def geo_name
      get_ext_name Phonelib::Core::EXT_GEO_NAMES,
                   Phonelib::Core::EXT_GEO_NAME_KEY
    end

    # Returns timezone of parsed phone number or nil if number is invalid or
    # there is no timezone specified in db for this number
    def timezone
      get_ext_name Phonelib::Core::EXT_TIMEZONES,
                   Phonelib::Core::EXT_TIMEZONE_KEY
    end

    # Returns carrier of parsed phone number or nil if number is invalid or
    # there is no carrier specified in db for this number
    def carrier
      get_ext_name Phonelib::Core::EXT_CARRIERS,
                   Phonelib::Core::EXT_CARRIER_KEY
    end

    private

    # get name from extended phone data by keys
    #
    # ==== Attributes
    #
    # * +name_key+ - names array key from extended data hash
    # * +id_key+   - parameter id key in resolved extended data for number
    #
    def get_ext_name(names_key, id_key)
      if ext_data[id_key] > 0
        res = Phonelib.phone_ext_data[names_key][ext_data[id_key]]
        res.size == 1 ? res.first : res
      end
    end

    # returns extended data ids for current number
    def ext_data
      return @ext_data if @ext_data

      ext_keys = [
          Phonelib::Core::EXT_GEO_NAME_KEY,
          Phonelib::Core::EXT_TIMEZONE_KEY,
          Phonelib::Core::EXT_CARRIER_KEY
      ]
      result = {}
      ext_keys.each { |key| result[key] = 0 }

      return result unless possible?

      drill = Phonelib.phone_ext_data[Phonelib::Core::EXT_PREFIXES]

      e164.gsub('+', '').each_char do |num|
        drill = drill[num.to_i] || break

        ext_keys.each do |key|
          result[key] = drill[key] if drill[key]
        end
      end

      @ext_data = result
    end
  end
end