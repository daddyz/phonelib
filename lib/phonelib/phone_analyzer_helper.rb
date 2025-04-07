# frozen_string_literal: true

module Phonelib
  # @private helper methods for analyser
  module PhoneAnalyzerHelper
    private

    def decorate_analyze_result(result)
      if result.size == 1
        result
      else
        matched_countries = country_or_default_country(nil) & result.keys
        matched_countries = result.keys.take(1) if matched_countries.size == 0
        result = result.keep_if {|k, _v| matched_countries.include?(k) } if matched_countries
        Hash[result.take(1)]
      end
    end

    def original_starts_with_plus_or_double_zero?
      original_s[0] == Core::PLUS_SIGN || original_s[0..1] == '00'
    end

    # converts symbols in phone to numbers
    def vanity_converted(phone)
      return phone unless Phonelib.vanity_conversion

      (phone || '').gsub(cr('[a-zA-Z]')) do |c|
        c.upcase!
        # subtract "A"
        n = (c.ord - 65) / 3
        # account for #7 & #9 which have 4 chars
        n -= 1 if c.match(Core::VANITY_4_LETTERS_KEYS_REGEX)
        (n + 2).to_s
      end
    end

    # defines if to validate against single country or not
    def passed_country(country)
      code = country_prefix(country)
      if !Phonelib.ignore_plus && Core::PLUS_SIGN == @original[0] && code && !sanitized.start_with?(code)
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
      Phonelib.phone_regexp_cache[regexp] ||= Regexp.new(block_given? ? yield(regexp) : regexp).freeze
    end

    # defines whether country can have double country prefix in number
    def country_can_dp?(country)
      Phonelib.phone_data[country] &&
        Phonelib.phone_data[country][Core::DOUBLE_COUNTRY_PREFIX_FLAG] &&
        !original_starts_with_plus_or_double_zero? &&
        original_s.start_with?(Phonelib.phone_data[country][Core::COUNTRY_CODE])
    end

    # changes phone to with/without double country prefix
    def changed_dp_phone(country, phone)
      data = Phonelib.phone_data[country]
      return if data.nil? || data[Core::DOUBLE_COUNTRY_PREFIX_FLAG].nil?

      country_code = Phonelib.phone_data[country][Core::COUNTRY_CODE]
      if phone.start_with? country_code * 2
        # remove double prefix in case it is there
        phone.gsub(cr("^#{country_code}"), '')
      else
        "#{country_code}#{phone}"
      end
    end

    # checks if country can have numbers with double country prefixes
    #
    # ==== Attributes
    #
    # * +data+ - country data used for parsing
    # * +phone+ - phone number being parsed
    # * +parsed+ - parsed regex match for phone
    def double_prefix_allowed?(data, phone, parsed = {})
      data[Core::DOUBLE_COUNTRY_PREFIX_FLAG] &&
        phone =~ cr("^#{data[Core::COUNTRY_CODE]}") &&
        parsed && (parsed[:valid].nil? || parsed[:valid].empty?) &&
        !original_starts_with_plus_or_double_zero?
    end

    # Returns original number passed if it's a string or empty string otherwise
    def original_s
      @original_s ||= @original.is_a?(String) ? @original : ''
    end

    # Get country that was provided or default country in needable format
    #
    # ==== Attributes
    #
    # * +country+ - country passed for parsing
    def country_or_default_country(country)
      country ||= (original_starts_with_plus_or_double_zero? ? nil : Phonelib.default_country)

      if country.is_a?(Array)
        country.compact.map { |e| e.to_s.upcase }
      else
        [country && country.to_s.upcase]
      end
    end

    # constructs full regex for phone validation for provided phone data
    # (international prefix, country code, national prefix, valid number)
    #
    # ==== Attributes
    #
    # * +data+ - country data hash
    # * +country_optional+ - whether to put country code as optional group
    def full_regex_for_data(data, type, country_optional = true)
      regex = +"^0{2}?(#{data[Core::INTERNATIONAL_PREFIX]})?(#{data[Core::COUNTRY_CODE]})#{country_optional ? '?' : ''}(#{data[Core::NATIONAL_PREFIX_FOR_PARSING] || data[Core::NATIONAL_PREFIX]})?"
      if data[Core::TYPES]
        regex << "("
        regex << type_regex(data[Core::TYPES][Core::GENERAL], type)
        regex << ")"
      end
      regex << "$"

      cr(regex)
    end

    # Returns regex for type with special types if needed
    #
    # ==== Attributes
    #
    # * +data+ - country types data for single type
    # * +type+ - possible or valid regex type needed
    def type_regex(data, type)
      if Phonelib.parse_special && data[Core::SHORT] && data[Core::SHORT][type]
        "#{data[type]}|#{data[Core::SHORT][type]}"
      else
        data[type]
      end
    end

    # Check if phone match country data
    #
    # ==== Attributes
    #
    # * +phone+ - phone number for parsing
    # * +data+  - country data
    def phone_match_data?(phone, data, possible = false)
      return unless phone.match?(cr("^0{2}?(#{data[Core::INTERNATIONAL_PREFIX]})?#{data[Core::COUNTRY_CODE]}"))

      type = possible ? Core::POSSIBLE_PATTERN : Core::VALID_PATTERN
      phone.match full_regex_for_data(data, type, false)
    end

    # checks if types has both :mobile and :fixed_line and replaces it with
    # :fixed_or_mobile in case both present
    def sanitize_fixed_mobile(types)
      Core::POSSIBLE_VALID_ARRAY.each do |key|
        if (Core::FIXED_LINE_OR_MOBILE_ARRAY - types[key]).empty?
          types[key] = types[key] - Core::FIXED_LINE_OR_MOBILE_ARRAY + Core::FIXED_OR_MOBILE_ARRAY
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
      Core::TYPES_DESC_KEYS - exclude_list + fixed_and_mobile_keys(data)
    end

    # Checks if fixed line pattern and mobile pattern are the same and returns
    # appropriate keys
    #
    # ==== Attributes
    #
    # * +data+  - country data
    def fixed_and_mobile_keys(data)
      if data[Core::FIXED_LINE] == data[Core::MOBILE]
        Core::FIXED_OR_MOBILE_ARRAY
      else
        Core::FIXED_LINE_OR_MOBILE_ARRAY
      end
    end

    # Checks if passed number matches valid and possible patterns
    #
    # ==== Attributes
    #
    # * +number+ - phone number for validation
    # * +p_regex+ - possible regex pattern for validation
    # * +v_regex+ - valid regex pattern for validation
    # * +not_valid+ - specifies that number is not valid by general desc pattern
    def number_valid_and_possible?(number, p_regex, v_regex, not_valid = false)
      possible = number_match?(number, p_regex)

      return [!not_valid && possible, possible] if p_regex == v_regex
      valid = !not_valid && possible && number_match?(number, v_regex)

      [valid && possible, possible]
    end

    # Checks number against regex and compares match length
    #
    # ==== Attributes
    #
    # * +number+ - phone number for validation
    # * +regex+ - regex for perfoming a validation
    def number_match?(number, regex)
      match = number.match(cr("^(?:#{regex})$"))
      match && match.to_s.length == number.length
    end
  end
end
