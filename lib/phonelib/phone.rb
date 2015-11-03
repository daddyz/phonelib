module Phonelib
  # class for parsed phone number, includes validation and formatting methods
  class Phone
    # defining reader methods for class variables
    # original phone number passed for parsing
    attr_reader :original
    # phone extension passed for parsing after a number
    attr_reader :extension

    # including module that has all phone analyzing methods
    include Phonelib::PhoneAnalyzer
    include Phonelib::PhoneExtendedData

    # class initialization method
    #
    # ==== Attributes
    #
    # * +phone+   - Phone number for parsing
    # * +country+ - Country specification for parsing. Must be ISO code of
    #   country (2 letters) like 'US', 'us' or :us for United States
    #
    def initialize(original, country = nil)
      @original, @extension = separate_extension(original)
      @extension.gsub!(/[^0-9]/, '') if @extension

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
      @sanitized ||= @original && @original.gsub(/[^0-9]+/, '') || ''
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

    # Return valid country
    def valid_country
      @valid_country ||= get_main_country(valid_countries)
    end

    # Returns first country that matched valid patterns
    def country
      @country ||= valid_country || get_main_country(countries)
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

    # returns area code of parsed number
    def area_code
      return nil unless possible?
      format_match, format_string = get_formatting_data

      if format_string =~ /^.*[0-9]+.*\$1/ && format_match
        format_string.gsub(/\$1.*$/, format_match[1]).gsub(/[^\d]+/, '')
      end
    end

    # returns local number
    def local_number
      return national unless possible?
      format_match, format_string = get_formatting_data

      if format_string =~ /^.*[0-9]+.*\$1/ && format_match
        format_string.gsub(/^.*\$2/, '$2').
            gsub(/\$\d/) { |el| format_match[el[1].to_i] }
      else
        national
      end
    end

    # Returns formatted national number
    def national
      return @national_number unless valid?
      format_match, format_string = get_formatting_data

      if format_match
        format_string.gsub(/\$\d/) { |el| format_match[el[1].to_i] }
      else
        @national_number
      end
    end

    # Returns e164 formatted phone number
    def international
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

    # returns international formatted number with extension added
    def full_international
      "#{international}#{formatted_extension}"
    end

    # returns e164 format of phone with extension added
    def full_e164
      "#{e164}#{formatted_extension}"
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
      @data.find do |iso2, data|
        country == iso2 && data[:valid].any?
      end.is_a? Array
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

    private

    # returns extension with separator defined
    def formatted_extension
      return '' unless @extension

      "#{Phonelib.extension_separator}#{@extension}"
    end

    # extracts extension from passed phone number if provided
    def separate_extension(original)
      regex = cr("[#{Phonelib.extension_separate_symbols}]")
      split = (original || '').split regex
      [split.first, split[1..-1] && split[1..-1].join]
    end

    # get main country for code among provided countries
    def get_main_country(countries_array)
      countries_array.find do |iso2|
        @data[iso2][Core::MAIN_COUNTRY_FOR_CODE] == 'true'
      end || countries_array.first
    end

    # Get needable data for formatting phone as national number
    def get_formatting_data
      return @formatting_data if @formatting_data

      format = @data[country][:format]
      prefix = @data[country][Core::NATIONAL_PREFIX]
      rule = (format[Core::NATIONAL_PREFIX_RULE] ||
          @data[country][Core::NATIONAL_PREFIX_RULE] || '$1')

      # change rule's constants to values
      rule.gsub!(/(\$NP|\$FG)/, '$NP' => prefix, '$FG' => '$1')

      # add space to format groups, change first group to rule,
      format_string = format[:format].gsub(/(\d)\$/, '\\1 $').gsub('$1', rule)

      @formatting_data =
          [@national_number.match(/#{format[Core::PATTERN]}/), format_string]
    end
  end
end
