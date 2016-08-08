module Phonelib
  # @private helper methods for analyser
  module PhoneAnalyzerHelper
    private

    # defines if to validate against single country or not
    def passed_country(country)
      code = country_prefix(country)
      if @original.start_with?('+') && code && !sanitized.start_with?(code)
        # in case number passed with + but it doesn't start with passed
        # country prefix
        country = nil
      end
      country
    end

    # returns country prefix for provided country or nil
    def country_prefix(country)
      country = country.to_s.upcase
      Phonelib.phone_data[country] && \
        Phonelib.phone_data[country][Core::COUNTRY_CODE]
    end

    # caches regular expression, reusing it for later lookups
    def cr(regexp)
      Phonelib.phone_regexp_cache[regexp] ||= Regexp.new(regexp)
    end

    # checks if country can have numbers with double country prefixes
    #
    # ==== Attributes
    #
    # * +data+ - country data used for parsing
    # * +phone+ - phone number being parsed
    # * +parsed+ - parsed regex match for phone
    def allows_double_prefix(data, phone, parsed)
      data[Core::DOUBLE_COUNTRY_PREFIX_FLAG] &&
        phone =~ cr("^#{data[Core::COUNTRY_CODE]}") &&
        parsed && (parsed[:valid].nil? || parsed[:valid].empty?)
    end

    # Returns original number passed if it's a string or empty string otherwise
    def original_string
      @original.is_a?(String) ? @original : ''
    end

    # Get country that was provided or default country in needable format
    #
    # ==== Attributes
    #
    # * +country+ - country passed for parsing
    def country_or_default_country(country)
      country ||= (original_string.start_with?('+') ? nil : Phonelib.default_country)
      country && country.to_s.upcase
    end

    # constructs full regex for phone validation for provided phone data
    # (international prefix, country code, national prefix, valid number)
    #
    # ==== Attributes
    #
    # * +data+ - country data hash
    # * +country_optional+ - whether to put country code as optional group
    def full_regex_for_data(data, type, country_optional = true)
      regex = []
      regex << "(#{data[Core::INTERNATIONAL_PREFIX]})?"
      regex << if country_optional
                 "(#{data[Core::COUNTRY_CODE]})?"
               else
                 data[Core::COUNTRY_CODE]
               end
      regex << "(#{data[Core::NATIONAL_PREFIX_FOR_PARSING] || data[Core::NATIONAL_PREFIX]})?"
      regex << "(#{data[Core::TYPES][Core::GENERAL][type]})"

      cr("^#{regex.join}$")
    end

    # Check if phone match country data
    #
    # ==== Attributes
    #
    # * +phone+ - phone number for parsing
    # * +data+  - country data
    def phone_match_data?(phone, data, possible = false)
      country_code = "#{data[Core::COUNTRY_CODE]}"
      inter_prefix = "(#{data[Core::INTERNATIONAL_PREFIX]})?"
      return unless phone.match cr("^#{inter_prefix}#{country_code}")

      type = possible ? Core::POSSIBLE_PATTERN : Core::VALID_PATTERN
      phone.match full_regex_for_data(data, type, false)
    end

    # checks if types has both :mobile and :fixed_line and replaces it with
    # :fixed_or_mobile in case both present
    def sanitize_fixed_mobile(types)
      fixed_mobile = [Core::FIXED_LINE, Core::MOBILE]
      [:possible, :valid].each do |key|
        if (fixed_mobile - types[key]).empty?
          types[key] = types[key] - fixed_mobile + [Core::FIXED_OR_MOBILE]
        end
      end
      types
    end

    # returns array of phone types for check for current country data
    #
    # ==== Attributes
    #
    # * +data+  - country data hash
    def types_for_check(data)
      exclude_list = PhoneAnalyzer::NOT_FOR_CHECK
      exclude_list += Phonelib::Core::SHORT_CODES unless Phonelib.parse_special
      Core::TYPES_DESC.keys - exclude_list + fixed_and_mobile_keys(data)
    end

    # Checks if fixed line pattern and mobile pattern are the same and returns
    # appropriate keys
    #
    # ==== Attributes
    #
    # * +data+  - country data
    def fixed_and_mobile_keys(data)
      if data[Core::FIXED_LINE] == data[Core::MOBILE]
        [Core::FIXED_OR_MOBILE]
      else
        [Core::FIXED_LINE, Core::MOBILE]
      end
    end

    # Checks if passed number matches valid and possible patterns
    #
    # ==== Attributes
    #
    # * +number+ - phone number for validation
    # * +possible_pattern+ - possible pattern for validation
    # * +national_pattern+ - valid pattern for validation
    # * +not_valid+ - specifies that number is not valid by general desc pattern
    def number_valid_and_possible?(number, possible_pattern, national_pattern, not_valid = false)
      possible_match = number.match(cr("^(?:#{possible_pattern})$"))
      possible = possible_match && possible_match.to_s.length == number.length

      return [!not_valid && possible, possible] if possible_pattern == national_pattern
      valid = false
      if !not_valid && possible
        # doing national pattern match only in case possible matches
        national_match = number.match(cr("^(?:#{national_pattern})$"))
        valid = national_match && national_match.to_s.length == number.length
      end

      [valid && possible, possible]
    end
  end
end
