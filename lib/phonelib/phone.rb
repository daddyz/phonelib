module Phonelib
  # class for parsed phone number, includes basic validation methods
  class Phone
    # defining reader methods for class variables
    attr_reader :original, :sanitized, :national_number

    # class initialization method
    #
    # ==== Attributes
    #
    # * +phone+ - Phone number for parsing
    # * +country_data+ - Hash of data for parsing
    #
    def initialize(phone, country_data)
      @original = phone
      @sanitized = sanitize_phone(@original)
      @analyzed_data = {}
      analyze_phone(country_data) unless @sanitized.empty?
    end

    # Returns all phone types that matched valid patterns
    def types
      @analyzed_data.flat_map {|iso2, data| data[:valid]}.uniq
    end

    # Returns first phone type that matched
    def type
      types.first
    end

    # Returns all countries that matched valid patterns
    def countries
      @analyzed_data.map {|iso2, data| iso2}
    end

    # Returns first country that matched valid patterns
    def country
      countries.first
    end

    # Returns whether a current parsed phone number is valid
    def valid?
      @analyzed_data.select {|iso2, data| data[:valid].any? }.any?
    end

    # Returns whether a current parsed phone number is invalid
    def invalid?
      !valid?
    end

    # Returns whether a current parsed phone number is possible
    def possible?
      @analyzed_data.select {|iso2, data| data[:possible].any? }.any?
    end

    # Returns whether a current parsed phone number is impossible
    def impossible?
      !possible?
    end

    # Returns whether a current parsed phone number is valid for specified
    # country
    #
    # ==== Attributes
    #
    # * +country+ - ISO code of country (2 letters) like 'US' for United States
    #
    def valid_for_country?(country)
      @analyzed_data.select {|iso2, data| country == iso2 &&
          data[:valid].any? }.any?
    end

    # Returns whether a current parsed phone number is invalid for specified
    # country
    #
    # ==== Attributes
    #
    # * +country+ - ISO code of country (2 letters) like 'US' for United States
    #
    def invalid_for_country?(country)
      @analyzed_data.select {|iso2, data| country == iso2 &&
          data[:valid].any? }.empty?
    end

    private
    # Analyze current phone with provided data hash
    def analyze_phone(country_data)
      possible_countries = country_data.select do |data|
        @sanitized.start_with?(data[:countryCode])
      end

      possible_countries.each do |country_data|
        next if country_data[:types].empty?

        prefix_length = country_data[:countryCode].length
        @national_number = @sanitized[prefix_length..@sanitized.length]
        @analyzed_data[country_data[:id]] =
            get_all_number_types(@national_number, country_data[:types])
      end
    end

    # Returns all valid and possible phone number types for currently parsed
    # phone for provided data hash.
    def get_all_number_types(number, data)
      response = {valid: [], possible: []}

      return response if data[Core::GENERAL].empty?
      return response unless number_valid_and_possible?(number,
                                                        data[Core::GENERAL])

      if data[Core::FIXED_LINE] == data[Core::MOBILE]
        same_fixed_and_mobile = true
        additional_check = [ Core::FIXED_LINE ]
      else
        same_fixed_and_mobile = false
        additional_check = [ Core::FIXED_LINE, Core::MOBILE ]
      end

      (Core::TYPES.keys - Core::NOT_FOR_CHECK + additional_check).each do |type|
        next if data[type].nil? || data[type].empty?

        if number_possible?(number, data[type])
          if same_fixed_and_mobile && same_types.include?(type)
            put_type = Core::FIXED_OR_MOBILE
          else
            put_type = type
          end
          response[:possible] << put_type
          response[:valid] << put_type if number_valid_and_possible?(number,
                                                                     data[type])
        end
      end

      response
    end

    # Checks if passed number matches both valid and possible patterns
    def number_valid_and_possible?(number, regexes)
      national_pattern = regexes[:nationalNumberPattern]
      possible_pattern = regexes[:possibleNumberPattern] || national_pattern
      national_match = number.match(/^(?:#{national_pattern})$/)
      possible_match = number.match(/^(?:#{possible_pattern})$/)

      national_match && possible_match &&
          national_match.to_s.length == number.length &&
          possible_match.to_s.length == number.length
    end

    # Checks if passed number matches possible pattern
    def number_possible?(number, regexes)
      possible_match = number.match(/^(?:#{regexes[:possibleNumberPattern]})$/)
      possible_match && possible_match.to_s.length == number.length
    end

    # Sanitizes passed phone number. Returns only digits from passed string.
    def sanitize_phone(phone)
      phone && phone.gsub(/[^0-9]+/, '') || ''
    end
  end
end