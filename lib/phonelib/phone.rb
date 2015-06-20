module Phonelib
  # class for parsed phone number, includes validation and formatting methods
  class Phone
    # defining reader methods for class variables
    attr_reader :original # original phone number passed for parsing

    # including module that has all phone analyzing methods
    include Phonelib::PhoneAnalyzer

    # class initialization method
    #
    # ==== Attributes
    #
    # * +phone+   - Phone number for parsing
    # * +country+ - Country specification for parsing. Must be ISO code of
    #   country (2 letters) like 'US', 'us' or :us for United States
    #
    def initialize(original, country = nil)
      @original = original

      if sanitized.empty?
        @data = {}
      else
        @data = analyze(sanitized, @original.start_with?('+') ? nil : country)
        first = @data.values.first
        @national_number = first ? first[:national] : sanitized
      end
    end

    # method to get sanitized phone number (only numbers)
    def sanitized
      @original && @original.gsub(/[^0-9]+/, '') || ''
    end

    # Returns all phone types that matched valid patterns
    def types
      @data.flat_map { |iso2, data| data[:valid] }.uniq
    end

    # Returns all possible types that matched possible patterns
    def possible_types
      @data.flat_map { |iso2, data| data[:possible] }.uniq
    end

    # Returns first phone type that matched
    def type
      types.first
    end

    # Returns human representation of all matched phone types
    def human_types
      types.map { |type| Core::TYPES_DESC[type] }
    end

    # Return human representation of phone type
    def human_type
      Core::TYPES_DESC[type]
    end

    # Returns all countries that matched valid patterns
    def countries
      @data.map { |iso2, data| iso2 }
    end

    # Return countries with valid patterns
    def valid_countries
      @valid_countries ||= countries.select do |iso2|
        @data[iso2][:valid].any?
      end
    end

    # Returns first country that matched valid patterns
    def country
      @country ||= begin
        valid_countries.find do |iso2|
          @data[iso2][Core::MAIN_COUNTRY_FOR_CODE] == 'true'
        end || valid_countries.first || countries.first
      end
    end

    # Returns the country code from the original phone number.
    def country_code
      if country_data = Phonelib.phone_data[country]
        country_data[:country_code]
      end
    end

    # Returns whether a current parsed phone number is valid
    def valid?
      @data.select { |iso2, data| data[:valid].any? }.any?
    end

    # Returns whether a current parsed phone number is invalid
    def invalid?
      !valid?
    end

    # Returns whether a current parsed phone number is possible
    def possible?
      @data.select { |iso2, data| data[:possible].any? }.any?
    end

    # Returns whether a current parsed phone number is impossible
    def impossible?
      !possible?
    end

    # Returns formatted national number
    def national
      return @national_number unless valid?
      format, prefix, rule = get_formatting_data

      # add space to format groups, change first group to rule,
      # change rule's constants to values
      format_string = format[:format].gsub(/(\d)\$/, '\\1 $').gsub('$1', rule)
          .gsub(/(\$NP|\$FG)/, '$NP' => prefix, '$FG' => '$1')

      if matches = @national_number.match(/#{format[Core::PATTERN]}/)
        format_string.gsub(/\$\d/) { |el| matches[el[1].to_i] }
      else
        @national_number
      end
    end

    # Returns e164 formatted phone number
    def international
      sanitized = self.sanitized
      return nil if sanitized.nil? || sanitized.empty?
      return "+#{sanitized}" unless valid?

      format = @data[country][:format]
      if matches = @national_number.match(/#{format[Core::PATTERN]}/)
        fmt = format[:intl_format] || format[:format]
        national = fmt.gsub(/\$\d/) { |el| matches[el[1].to_i] }
      else
        national = @national_number
      end

      "+#{@data[country][Core::COUNTRY_CODE]} #{national}"
    end

    # Returns e164 unformatted phone number
    def e164
      international = self.international
      international and international.gsub /[^+0-9]/, ''
    end

    # Returns whether a current parsed phone number is valid for specified
    # country
    #
    # ==== Attributes
    #
    # * +country+ - ISO code of country (2 letters) like 'US', 'us' or :us
    #   for United States
    #
    def valid_for_country?(country)
      country = country.to_s.upcase
      @data.select do |iso2, data|
        country == iso2 && data[:valid].any?
      end.any?
    end

    # Returns whether a current parsed phone number is invalid for specified
    # country
    #
    # ==== Attributes
    #
    # * +country+ - ISO code of country (2 letters) like 'US', 'us' or :us
    #   for United States
    #
    def invalid_for_country?(country)
      !valid_for_country?(country)
    end

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

    # Get needable data for formatting phone as national number
    def get_formatting_data
      format = @data[country][:format]
      prefix = @data[country][Core::NATIONAL_PREFIX]
      rule = (format[Core::NATIONAL_PREFIX_RULE] ||
          @data[country][Core::NATIONAL_PREFIX_RULE] || '$1')

      [format, prefix, rule]
    end
  end
end
