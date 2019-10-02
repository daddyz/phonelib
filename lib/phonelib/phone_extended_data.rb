module Phonelib
  # module provides extended data methods for parsed phone
  module PhoneExtendedData
    # @private keys for extended data
    EXT_KEYS = [
      Phonelib::Core::EXT_GEO_NAME_KEY,
      Phonelib::Core::EXT_TIMEZONE_KEY,
      Phonelib::Core::EXT_CARRIER_KEY
    ]

    # Returns geo name of parsed phone number or nil if number is invalid or
    # there is no geo name specified in db for this number
    # @return [String|nil] geo name for parsed phone
    def geo_name
      get_ext_name Phonelib::Core::EXT_GEO_NAMES,
                   Phonelib::Core::EXT_GEO_NAME_KEY
    end

    # Returns timezone of parsed phone number or nil if number is invalid or
    # there is no timezone specified in db for this number
    # @return [String|nil] timezone for parsed phone
    def timezone
      get_ext_name Phonelib::Core::EXT_TIMEZONES,
                   Phonelib::Core::EXT_TIMEZONE_KEY
    end

    # Returns carrier of parsed phone number or nil if number is invalid or
    # there is no carrier specified in db for this number
    # @return [String|nil] carrier for parsed phone
    def carrier
      get_ext_name Phonelib::Core::EXT_CARRIERS,
                   Phonelib::Core::EXT_CARRIER_KEY
    end

    # returns valid country name
    def valid_country_name
      return unless valid?

      Phonelib.phone_ext_data[Phonelib::Core::EXT_COUNTRY_NAMES][valid_country]
    end

    private

    # @private get name from extended phone data by keys
    #
    # ==== Attributes
    #
    # * +name_key+ - names array key from extended data hash
    # * +id_key+   - parameter id key in resolved extended data for number
    #
    def get_ext_name(names_key, id_key)
      return nil unless ext_data[id_key]

      res = Phonelib.phone_ext_data[names_key][ext_data[id_key]]
      return nil unless res
      res.size == 1 ? res.first : res
    end

    # @private returns extended data ids for current number
    def ext_data
      return @ext_data if @ext_data

      result = default_ext_data
      return result unless possible?

      drill = Phonelib.phone_ext_data[Phonelib::Core::EXT_PREFIXES]

      e164.delete('+').each_char do |num|
        drill = drill[num.to_i] || break

        EXT_KEYS.each do |key|
          result[key] = drill[key] if drill[key]
        end
      end

      @ext_data = result
    end

    # @private default extended data
    def default_ext_data
      result = {}
      EXT_KEYS.each { |key| result[key] = nil }
      result
    end
  end
end
