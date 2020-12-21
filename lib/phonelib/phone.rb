module Phonelib
  # class for parsed phone number, includes validation and formatting methods
  class Phone
    # @!attribute [r] original
    # @return [String] original phone number passed for parsing
    attr_reader :original
    # @!attribute [r] extension
    # @return [String] phone extension passed for parsing after a number
    attr_reader :extension

    # including module that has all phone analyzing methods
    include Phonelib::PhoneAnalyzer
    include Phonelib::PhoneExtendedData
    include Phonelib::PhoneFormatter

    # class initialization method
    # @param phone [String] Phone number for parsing
    # @param country [String|Symbol] Country specification for parsing.
    #   Must be ISO code of country (2 letters) like 'US', 'us' or :us
    #   for United States
    # @return [Phonelib::Phone] parsed phone instance
    def initialize(phone, country = nil)
      @original, @extension = separate_extension(phone.to_s)
      @extension.gsub!(/[^0-9]/, '') if @extension

      if sanitized.empty?
        @data = {}
      else
        @data = analyze(sanitized, passed_country(country))
        first = @data.values.first
        @national_number = first ? first[:national] : sanitized
      end
    end

    # method returns string representation of parsed phone
    def to_s
      valid? ? e164 : original
    end

    # Compare a phone number against a string or other parsed number
    # @param other [String|Phonelib::Phone] Phone number to compare against
    # @return [Boolean] result of equality comparison
    def ==(other)
      other = Phonelib.parse(other) unless other.is_a?(Phonelib::Phone)
      return (e164 == other.e164) if valid? && other.valid?
      original == other.original
    end

    # method to get sanitized phone number (only numbers)
    # @return [String] Sanitized phone number
    def sanitized
      @sanitized ||=
          vanity_converted(@original).gsub(
              Phonelib.strict_check ? cr('^\+') : cr(Phonelib.sanitize_regex),
              '')
    end

    # Returns all phone types that matched valid patterns
    # @return [Array] all valid phone types
    def types
      @types ||= @data.flat_map { |_iso2, data| data[:valid] }.uniq
    end

    # Returns all possible types that matched possible patterns
    # @return [Array] all possible phone types
    def possible_types
      @possible_types ||= @data.flat_map { |_iso2, data| data[:possible] }.uniq
    end

    # Returns first phone type that matched
    # @return [Symbol] valid phone type
    def type
      types.first
    end

    # Returns human representation of all matched phone types
    # @return [Array] Array of human readable valid phone types
    def human_types
      types.map { |type| Core::TYPES_DESC[type] }
    end

    # Return human representation of phone type
    # @return [String] Human readable valid phone type
    def human_type
      Core::TYPES_DESC[type]
    end

    # Returns all countries that matched valid patterns
    # @return [Array] Possible ISO2 country codes array
    def countries
      @data.map { |iso2, _data| iso2 }
    end

    # Return countries with valid patterns
    # @return [Array] Valid ISO2 country codes array
    def valid_countries
      @valid_countries ||= countries.select do |iso2|
        @data[iso2][:valid].any?
      end
    end

    # Return valid country
    # @return [String] valid ISO2 country code
    def valid_country
      @valid_country ||= main_country(valid_countries)
    end

    # Returns first country that matched valid patterns
    # @return [String] valid country ISO2 code or first matched country code
    def country
      @country ||= valid_country || main_country(countries)
    end

    # Returns whether a current parsed phone number is valid
    # @return [Boolean] parsed phone is valid
    def valid?
      @valid ||= @data.select { |_iso2, data| data[:valid].any? }.any?
    end

    # Returns whether a current parsed phone number is invalid
    # @return [Boolean] parsed phone is invalid
    def invalid?
      !valid?
    end

    # Returns whether a current parsed phone number is possible
    # @return [Boolean] parsed phone is possible
    def possible?
      @possible ||= @data.select { |_iso2, data| data[:possible].any? }.any?
    end

    # Returns whether a current parsed phone number is impossible
    # @return [Boolean] parsed phone is impossible
    def impossible?
      !possible?
    end

    # returns local number
    # @return [String] local number
    def local_number
      return national unless possible?
      format_match, format_string = formatting_data

      if format_string =~ /^.*[0-9]+.*\$1/ && format_match
        format_string.gsub(/^.*\$2/, '$2')
          .gsub(/\$\d/) { |el| format_match[el[1].to_i] }
      else
        national
      end
    end

    # Returns whether a current parsed phone number is valid for specified
    # country
    # @param country [String|Symbol] ISO code of country (2 letters) like 'US',
    #   'us' or :us for United States
    # @return [Boolean] parsed phone number is valid
    def valid_for_country?(country)
      country = country.to_s.upcase
      tdata = analyze(sanitized, passed_country(country))
      tdata.find do |iso2, data|
        country == iso2 && data[:valid].any?
      end.is_a? Array
    end

    # Returns whether a current parsed phone number is invalid for specified
    # country
    # @param country [String|Symbol] ISO code of country (2 letters) like 'US',
    #   'us' or :us for United States
    # @return [Boolean] parsed phone number is invalid
    def invalid_for_country?(country)
      !valid_for_country?(country)
    end

    private

    # @private extracts extension from passed phone number if provided
    def separate_extension(original)
      regex = if Phonelib.extension_separate_symbols.is_a?(Array)
                cr("#{Phonelib.extension_separate_symbols.join('|')}")
              else
                cr("[#{Phonelib.extension_separate_symbols}]")
              end
      split = (original || '').split regex
      [split.first || '', split[1..-1] && split[1..-1].join || '']
    end

    # @private get main country for code among provided countries
    def main_country(countries_array)
      countries_array.find do |iso2|
        @data[iso2][Core::MAIN_COUNTRY_FOR_CODE] == 'true'
      end || countries_array.first
    end
  end
end
