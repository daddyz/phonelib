module Phonelib
  # module includes all formatting methods
  module PhoneFormatter
    # Returns formatted national number
    # @param formatted [Boolean] whether to return numbers only or formatted
    # @return [String] formatted national number
    def national(formatted = true)
      return @national_number unless valid?
      format_match, format_string = get_formatting_data

      if format_match
        out = format_string.gsub(/\$\d/) { |el| format_match[el[1].to_i] }
        formatted ? out : out.gsub(/[^0-9]/, '')
      else
        @national_number
      end
    end

    # Returns e164 formatted phone number
    # @param formatted [Boolean] whether to return numbers only or formatted
    # @return [String] formatted international number
    def international(formatted = true)
      return nil if sanitized.nil? || sanitized.empty?
      return "+#{country_prefix_or_not}#{sanitized}" unless valid?
      return "#{@data[country][Core::COUNTRY_CODE]}#{@national_number}" unless formatted

      format = @data[country][:format]
      if matches = @national_number.match(/#{format[Core::PATTERN]}/)
        fmt = format[:intl_format] || format[:format]
        national = fmt.gsub(/\$\d/) { |el| matches[el[1].to_i] }
      else
        national = @national_number
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
      international and international.gsub /[^+0-9]/, ''
    end

    # Returns whether a current parsed phone number is valid for specified
    # country
    # @param country [String|Symbol] ISO code of country (2 letters) like 'US', 'us' or :us
    #   for United States
    # @return [Boolean] parsed phone number is valid
    def valid_for_country?(country)
      country = country.to_s.upcase
      @data.find do |iso2, data|
        country == iso2 && data[:valid].any?
      end.is_a? Array
    end

    # Returns whether a current parsed phone number is invalid for specified
    # country
    # @param country [String|Symbol] ISO code of country (2 letters) like 'US', 'us' or :us
    #   for United States
    # @return [Boolean] parsed phone number is invalid
    def invalid_for_country?(country)
      !valid_for_country?(country)
    end

    private

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
