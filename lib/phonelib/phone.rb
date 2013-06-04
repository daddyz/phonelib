module Phonelib
  # class for parsed phone number, includes validation and formatting methods
  class Phone
    # defining reader methods for class variables
    attr_reader :original, # original phone number passed for parsing
                :sanitized # sanitized phone number representation

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
      @country ||= countries.detect do |iso2|
        !@analyzed_data[iso2][:valid].empty?
      end
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

    # Returns formatted national number
    def national
      return @national_number unless valid?
      format = @analyzed_data[country][:format]
      prefix = @analyzed_data[country][Core::NATIONAL_PREFIX]
      rule = (format[Core::NATIONAL_PREFIX_RULE] ||
          @analyzed_data[country][Core::NATIONAL_PREFIX_RULE] || '$1')

      # add space to format groups, change first group to rule,
      # change rule's constants to values
      format_string = format[:format].gsub(/(\d)\$/, "\\1 $").gsub('$1', rule).
          gsub(/(\$NP|\$FG)/, { '$NP' => prefix, '$FG' => '$1' })

      matches = @national_number.match(/#{format[:pattern]}/)
      format_string.gsub(/\$\d/) {|el| matches[el[1].to_i] }
    end

    # Returns e164 formatted phone number
    def international
      return "+#{@sanitized}" unless valid?
      national_number = national
      if national_prefix = @analyzed_data[country][Core::NATIONAL_PREFIX]
        national_number.gsub!(/^#{national_prefix}/, '')
        national_number.strip!
      end
      country_code = @analyzed_data[country][Core::COUNTRY_CODE]

      "+#{country_code} #{national_number}"
    end

    # Returns whether a current parsed phone number is valid for specified
    # country
    #
    # ==== Attributes
    #
    # * +country+ - ISO code of country (2 letters) like 'US', 'us' or :us for United States
    #
    def valid_for_country?(country)
      country = country.to_s.upcase
      @analyzed_data.select {|iso2, data| country == iso2 &&
          data[:valid].any? }.any?
    end

    # Returns whether a current parsed phone number is invalid for specified
    # country
    #
    # ==== Attributes
    #
    # * +country+ - ISO code of country (2 letters) like 'US', 'us' or :us for United States
    #
    def invalid_for_country?(country)
      country = country.to_s.upcase
      @analyzed_data.select {|iso2, data| country == iso2 &&
          data[:valid].any? }.empty?
    end

    private
    # Analyze current phone with provided data hash
    def analyze_phone(country_data)
      country_data.each do |data|
        if @sanitized.start_with? "#{data[:countryCode]}#{data[:leadingDigits]}"
          possible, valid = get_patterns(data[:types][Core::GENERAL])
          next unless /^#{data[:countryCode]}#{valid}$/ =~ @sanitized

          @national_number = @sanitized[data[:countryCode].length..-1]
          @analyzed_data[data[:id]] = data
          @analyzed_data[data[:id]][:format] = get_number_format(data[:formats])
          @analyzed_data[data[:id]].merge! all_number_types(data[:types])
        end
      end
    end

    # Returns all valid and possible phone number types for currently parsed
    # phone for provided data hash.
    def all_number_types(data)
      response = {valid: [], possible: []}

      additional_types = check_same_types(data)
      (Core::TYPES.keys - Core::NOT_FOR_CHECK + additional_types).each do |type|
        check_type = case type
                     when Core::FIXED_OR_MOBILE
                       Core::FIXED_LINE
                     else
                       type
                     end
        possible, valid = get_patterns(data[check_type])

        response[:possible] << type if number_possible?(possible)
        response[:valid] << type if number_valid_and_possible?(possible, valid)
      end

      response
    end

    # Gets matched number formating rule or default one
    def get_number_format(format_data)
      if format_data
        format_data.find { |f| /^#{f[:pattern]}$/ =~ @national_number }
      else
        Core::DEFAULT_NUMBER_FORMAT
      end
    end

    # Checks if fixed line pattern and mobile pattern are the same
    def check_same_types(data)
      if data[Core::FIXED_LINE] == data[Core::MOBILE]
        [ Core::FIXED_OR_MOBILE ]
      else
        [ Core::FIXED_LINE, Core::MOBILE ]
      end
    end

    # Returns array of two elements. Valid phone pattern and possible pattern
    def get_patterns(patterns)
      return [nil, nil] if patterns.nil?
      national_pattern = patterns[Core::VALID_PATTERN]
      possible_pattern = patterns[Core::POSSIBLE_PATTERN] || national_pattern

      [possible_pattern, national_pattern]
    end

    # Checks if passed number matches both valid and possible patterns
    def number_valid_and_possible?(possible_pattern, national_pattern)
      national_match = @national_number.match(/^(?:#{national_pattern})$/)
      possible_match = @national_number.match(/^(?:#{possible_pattern})$/)

      national_match && possible_match &&
          national_match.to_s.length == @national_number.length &&
          possible_match.to_s.length == @national_number.length
    end

    # Checks if passed number matches possible pattern
    def number_possible?(possible_pattern)
      possible_match = @national_number.match(/^(?:#{possible_pattern})$/)
      possible_match && possible_match.to_s.length == @national_number.length
    end

    # Sanitizes passed phone number. Returns only digits from passed string.
    def sanitize_phone(phone)
      phone && phone.gsub(/[^0-9]+/, '') || ''
    end
  end
end
