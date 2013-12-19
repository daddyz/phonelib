module Phonelib
  module PhoneAnalyzer

    # array of types not included for validation check in cycle
    NOT_FOR_CHECK = [:general_desc, :fixed_line, :mobile, :fixed_or_mobile]

    # analyze provided phone if it matches country data ang returns result of
    # analyze
    def analyze(phone, country_data)
      country_data.each do |data|
        if country_match = phone_match_data?(phone, data)
          return get_national_and_data(phone, data, country_match)
        end
      end
      [ '', {} ]
    end

    private

    # returns national number for provided phone and analyzing results for
    # provided phone number
    def get_national_and_data(phone, data, country_match)
      prefix_length = data[Core::COUNTRY_CODE].length
      prefix_length += country_match[1].length unless country_match[1].nil?
      national = phone[prefix_length..-1]
      data[:format] = get_number_format(national, data[Core::FORMATS])
      data.merge! all_number_types(national, data[Core::TYPES])
      [ national, { data[:id] => data } ]
    end

    # Check if sanitized phone match country data
    def phone_match_data?(phone, data)
      phone_code = "#{data[Core::COUNTRY_CODE]}#{data[Core::LEADING_DIGITS]}"
      inter_prefix = "(#{data[Core::INTERNATIONAL_PREFIX]})?"
      if phone.match(/^#{inter_prefix}#{phone_code}/)
        _possible, valid = get_patterns(data[Core::TYPES], Core::GENERAL)
        phone.match /^#{inter_prefix}#{data[Core::COUNTRY_CODE]}#{valid}$/
      end
    end

    # Get needable data for formatting phone as national number
    def get_formatting_data
      format = @analyzed_data[country][:format]
      prefix = @analyzed_data[country][Core::NATIONAL_PREFIX]
      rule = (format[Core::NATIONAL_PREFIX_RULE] ||
          @analyzed_data[country][Core::NATIONAL_PREFIX_RULE] || '$1')

      [format, prefix, rule]
    end

    # Returns all valid and possible phone number types for currently parsed
    # phone for provided data hash.
    def all_number_types(number, data)
      response = { valid: [], possible: [] }

      types_for_check(data).each do |type|
        possible, valid = get_patterns(data, type)

        response[:possible] << type if number_possible?(number, possible)
        response[:valid] << type if number_valid_and_possible?(number,
                                                               possible,
                                                               valid)
      end

      response
    end

    # returns array of phone types for check for current country data
    def types_for_check(data)
      Core::TYPES_DESC.keys - PhoneAnalyzer::NOT_FOR_CHECK +
          fixed_and_mobile_keys(data)
    end

    # Gets matched number formatting rule or default one
    def get_number_format(national, format_data)
      if format_data
        format_data.find do |format|
          (format[Core::LEADING_DIGITS].nil? \
              || /^#{format[Core::LEADING_DIGITS]}/ =~ national) \
          && /^#{format[Core::PATTERN]}$/ =~ national
        end
      else
        Core::DEFAULT_NUMBER_FORMAT
      end
    end

    # Checks if fixed line pattern and mobile pattern are the same and returns
    # appropriate keys
    def fixed_and_mobile_keys(data)
      if data[Core::FIXED_LINE] == data[Core::MOBILE]
        [Core::FIXED_OR_MOBILE]
      else
        [Core::FIXED_LINE, Core::MOBILE]
      end
    end

    # Returns array of two elements. Valid phone pattern and possible pattern
    def get_patterns(all_types, type)
      patterns = case type
                 when Core::FIXED_OR_MOBILE
                   all_types[Core::FIXED_LINE]
                 else
                   all_types[type]
                 end
      return [nil, nil] if patterns.nil?
      national_pattern = patterns[Core::VALID_PATTERN]
      possible_pattern = patterns[Core::POSSIBLE_PATTERN] || national_pattern

      [possible_pattern, national_pattern]
    end

    # Checks if passed number matches both valid and possible patterns
    def number_valid_and_possible?(number, possible_pattern, national_pattern)
      national_match = number.match(/^(?:#{national_pattern})$/)
      possible_match = number.match(/^(?:#{possible_pattern})$/)

      national_match && possible_match &&
          national_match.to_s.length == number.length &&
          possible_match.to_s.length == number.length
    end

    # Checks if passed number matches possible pattern
    def number_possible?(number, possible_pattern)
      possible_match = number.match(/^(?:#{possible_pattern})$/)
      possible_match && possible_match.to_s.length == number.length
    end
  end
end