module Phonelib
  # module includes all formatting methods
  module PhoneFormatter
    # Returns formatted national number
    # @param formatted [Boolean] whether to return numbers only or formatted
    # @return [String] formatted national number
    def national(formatted = true)
      return @national_number unless valid?
      format_match, format_string = formatting_data

      if format_match
        out = format_string.gsub(/\$\d/) { |el| format_match[el[1].to_i] }
        formatted ? out : out.gsub(/[^0-9]/, '')
      else
        @national_number
      end
    end

    # Returns the raw national number that was defined during parsing
    # @return [String] raw national number
    def raw_national
      return nil if sanitized.nil? || sanitized.empty?
      if valid?
        @national_number
      elsif country_code && sanitized.start_with?(country_code)
        sanitized[country_code.size..-1]
      else
        sanitized
      end
    end

    # Returns the country code from the original phone number.
    # @return [String] matched country phone code
    def country_code
      @country_code ||= Phonelib.phone_data[country] && \
                        Phonelib.phone_data[country][Core::COUNTRY_CODE]
    end

    # Returns e164 formatted phone number
    # @param formatted [Boolean] whether to return numbers only or formatted
    # @return [String] formatted international number
    def international(formatted = true)
      return nil if sanitized.empty?
      return "+#{country_prefix_or_not}#{sanitized}" unless valid?
      return country_code + @national_number unless formatted

      fmt = @data[country][:format]
      national = @national_number
      if (matches = @national_number.match(cr(fmt[Core::PATTERN])))
        fmt = fmt[:intl_format] || fmt[:format]
        national = fmt.gsub(/\$\d/) { |el| matches[el[1].to_i] }
      end

      "+#{country_code} #{national}"
    end

    # returns national formatted number with extension added
    # @return [String] formatted national number with extension
    def full_national
      "#{national}#{formatted_extension}"
    end

    # returns international formatted number with extension added
    # @return [String] formatted internation phone number with extension
    def full_international
      "#{international}#{formatted_extension}"
    end

    # returns e164 format of phone with extension added
    # @return [String] phone formatted in E164 format with extension
    def full_e164
      "#{e164}#{formatted_extension}"
    end

    # Returns e164 unformatted phone number
    # @return [String] phone formatted in E164 format
    def e164
      international = self.international
      international && international.gsub(/[^+0-9]/, '')
    end

    # returns area code of parsed number
    # @return [String|nil] parsed phone area code if available
    def area_code
      return nil unless area_code_possible?

      format_match, _format_string = formatting_data
      take_group = 1
      if type == Core::MOBILE && Core::AREA_CODE_MOBILE_TOKENS[country] && \
         format_match[1] == Core::AREA_CODE_MOBILE_TOKENS[country]
        take_group = 2
      end
      format_match[take_group]
    end

    private

    # @private defines if phone can have area code
    def area_code_possible?
      return false if impossible?

      # has national prefix
      return false unless @data[country][Core::NATIONAL_PREFIX] || country == 'IT'
      # fixed or mobile
      return false unless Core::AREA_CODE_TYPES.include?(type)
      # mobile && mexico, argentina, brazil
      return false if type == Core::MOBILE && !Core::AREA_CODE_MOBILE_COUNTRIES.include?(country)
      true
    end

    # @private defines whether to put country prefix or not
    def country_prefix_or_not
      return '' unless country_code
      sanitized.start_with?(country_code) ? '' : country_code
    end

    # @private returns extension with separator defined
    def formatted_extension
      return '' if @extension.nil? || @extension.empty?

      "#{Phonelib.extension_separator}#{@extension}"
    end

    # @private Get needable data for formatting phone as national number
    def formatting_data
      return @formatting_data if defined?(@formatting_data)

      data = @data[country]
      format = data[:format]
      prefix = data[Core::NATIONAL_PREFIX]
      rule = format[Core::NATIONAL_PREFIX_RULE] ||
             data[Core::NATIONAL_PREFIX_RULE] || '$1'

      # change rule's constants to values
      rule.gsub!(/(\$NP|\$FG)/, '$NP' => prefix, '$FG' => '$1')

      # add space to format groups, change first group to rule,
      format_string = format[:format].gsub(/(\d)\$/, '\\1 $').gsub('$1', rule)

      @formatting_data =
          [@national_number.match(/#{format[Core::PATTERN]}/), format_string]
    end
  end
end
