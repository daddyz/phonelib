# frozen_string_literal: true

module Phonelib
  # Framework-independent diagnostics and policy validation for a parsed phone.
  module PhoneValidation
    VALIDATION_OPTIONS = [:possible, :types, :countries, :extensions].freeze
    VALID_TYPE_NAMES = Core::TYPES_DESC_KEYS.map(&:to_s).freeze
    MAX_VALIDATION_VALUES = 300
    private_constant :VALIDATION_OPTIONS, :VALID_TYPE_NAMES,
                     :MAX_VALIDATION_VALUES

    # Returns an immutable result explaining whether this phone satisfies the
    # requested rules and, when it does not, why.
    # @param options [Hash] phone validation rules
    # @return [Phonelib::ValidationResult]
    def validation(options = {})
      validate_options!(options)
      possible = options.fetch(:possible, false)
      possibility = diagnostic_possibility
      validation_errors = intrinsic_validation_errors(possible, possibility)
      if validation_errors.empty?
        validation_errors.concat(policy_validation_errors(options, possible))
      end

      ValidationResult.new(self, validation_errors, possibility)
    end

    # Convenience accessor for validation diagnostics.
    # @param options [Hash] phone validation rules
    # @return [Phonelib::Errors]
    def errors(options = {})
      validation(options).errors
    end

    private

    def validate_options!(options)
      unknown_options = options.keys - VALIDATION_OPTIONS
      if unknown_options.any?
        raise ArgumentError, "unknown validation option: #{unknown_options.first}"
      end

      validate_boolean_option!(:possible, options.fetch(:possible, false))
      validate_boolean_option!(:extensions, options.fetch(:extensions, true))
      validate_collection_option!(:types, options[:types])
      validate_collection_option!(:countries, options[:countries])
    end

    def validate_boolean_option!(name, value)
      return if value == true || value == false

      raise ArgumentError, "#{name} must be true or false"
    end

    def validate_collection_option!(name, value)
      return if value.nil?

      values = value.is_a?(Array) ? value : [value]
      if values.size > MAX_VALIDATION_VALUES
        raise ArgumentError,
              "#{name} must contain at most #{MAX_VALIDATION_VALUES} values"
      end
      unless values.all? { |item| item.is_a?(String) || item.is_a?(Symbol) }
        raise ArgumentError, "#{name} must be a symbol, string, or array of them"
      end
      validate_type_names!(values) if name == :types
    end

    def validate_type_names!(values)
      unknown = values.find { |item| !VALID_TYPE_NAMES.include?(item.to_s) }
      raise ArgumentError, "unknown phone type: #{unknown}" if unknown
    end

    def intrinsic_validation_errors(possible, possibility)
      if possible
        return [] if possible?
        if possibility != :impossible
          return [ValidationError.new(:not_possible, possibility: possibility)]
        end
      end
      return [] if !possible && valid?
      return [ValidationError.new(:invalid)] if possibility != :impossible

      diagnostic_error = intrinsic_diagnostic_error
      return [diagnostic_error] if diagnostic_error

      [ValidationError.new(:not_possible)]
    end

    def intrinsic_diagnostic_error
      return ValidationError.new(:not_a_number) unless viable_input?
      parser_length = parser_national_length
      if parser_length && parser_length > 17
        return ValidationError.new(
          :too_long,
          actual_length: parser_length
        )
      end
      return ValidationError.new(:invalid_country_code) if passed_country_invalid?

      idd_remainder = digits_after_international_dialing_prefix
      if idd_remainder && idd_remainder.length <= 2
        return ValidationError.new(
          :too_short,
          actual_length: idd_remainder.length
        )
      end

      international_digits = international_digits_for_diagnostics
      if international_digits && country_calling_code_for(international_digits).nil?
        return ValidationError.new(:invalid_country_code)
      end
      national_length_error = short_national_number_error(international_digits)
      return national_length_error if national_length_error

      possibility_length_error
    end

    def viable_input?
      candidate = significant_original_s.sub(cr('[^0-9A-Za-z]+\z'), '')
      return false if Phonelib.strict_check && !sanitized.match?(cr('\A[0-9]+\z'))

      minimum_digits = candidate.match?(cr('\A[0-9]+\z')) ? 2 : 3
      sanitized.length >= minimum_digits
    end

    def parser_national_length
      international_digits = international_digits_for_diagnostics
      return sanitized.length unless international_digits

      country_code = country_calling_code_for(international_digits)
      international_digits.delete_prefix(country_code).length if country_code
    end

    def passed_country_invalid?
      return false if significant_original_s.start_with?(Core::PLUS_SIGN)

      passed_countries = Array(@passed_country).compact
      passed_countries.any? && passed_countries.none? do |country|
        Phonelib.phone_data.key?(normalize_passed_country(country))
      end
    end

    def short_national_number_error(international_digits)
      return unless international_digits

      country_code = country_calling_code_for(international_digits)
      national_digits = international_digits.delete_prefix(country_code)
      return unless national_digits.length < 2

      ValidationError.new(
        :too_short,
        actual_length: national_digits.length
      )
    end

    def possibility_length_error
      context = diagnostic_number_context
      return unless context

      national_digits, data = context
      lengths = possible_lengths_for(data)
      local_only_lengths = possible_local_only_lengths_for(data)
      return if lengths.empty? || lengths.include?(national_digits.length) ||
                local_only_lengths.include?(national_digits.length)

      code = if national_digits.length < lengths.min
               :too_short
             elsif national_digits.length > lengths.max
               :too_long
             else
               :invalid_length
             end
      ValidationError.new(
        code,
        actual_length: national_digits.length,
        expected_lengths: lengths
      )
    end

    def diagnostic_possibility
      return @diagnostic_possibility if defined?(@diagnostic_possibility)

      return :impossible if passed_country_invalid?
      return :impossible unless viable_input?
      return :possible if possible_special_number?

      context = diagnostic_number_context
      return possible? ? :possible : :impossible unless context

      national_digits, data = context
      length = national_digits.length
      return :possible if possible_lengths_for(data).include?(length)
      return :possible if additional_regex_possible?(national_digits, data)
      return :possible_local_only if possible_local_only_lengths_for(data).include?(length)

      :impossible
    end

    def possible_special_number?
      Phonelib.parse_special && (possible_types & Core::SHORT_CODES).any?
    end

    def additional_regex_possible?(national_digits, data)
      candidate_countries = countries.any? ? countries : [data[:id]]
      candidate_countries.any? do |country|
        regexes = Phonelib.additional_regexes[country]
        regexes && regexes.values.flatten.any? do |regex|
          national_digits.match?(cr("^(?:#{regex})$"))
        end
      end
    end

    def diagnostic_number_context
      international_digits = international_digits_for_diagnostics
      if international_digits
        country_code = country_calling_code_for(international_digits)
        return unless country_code

        countries_data = Phonelib.data_by_country_codes[country_code]
        data = countries_data.find do |candidate|
          candidate[Core::MAIN_COUNTRY_FOR_CODE] == 'true'
        end || countries_data.first
        national_digits = if valid? || possible?
                            @national_number
                          else
                            international_digits.delete_prefix(country_code)
                          end
        return [national_digits, data]
      end

      resolved_country = self.country
      data = resolved_country && Phonelib.phone_data[resolved_country]
      unless data
        supplied_country = Array(
          @passed_country || Phonelib.default_country
        ).compact.first
        data = supplied_country && Phonelib.phone_data[
          normalize_passed_country(supplied_country)
        ]
      end
      [@national_number || sanitized, data] if data
    end

    def international_digits_for_diagnostics
      if !Phonelib.ignore_plus &&
         significant_original_s.start_with?(Core::PLUS_SIGN)
        return sanitized
      end

      digits_after_international_dialing_prefix
    end

    def possible_lengths_for(data)
      general = data[Core::TYPES][Core::GENERAL]
      lengths = general[Core::POSSIBLE_LENGTHS]
      return lengths if lengths.is_a?(Array)

      regex = general[Core::POSSIBLE_PATTERN]
      return [] unless regex

      (1..17).select { |length| ('0' * length).match?(cr("^(?:#{regex})$")) }
    end

    def possible_local_only_lengths_for(data)
      lengths = data[Core::TYPES][Core::GENERAL][Core::POSSIBLE_LOCAL_ONLY_LENGTHS]
      lengths.is_a?(Array) ? lengths : []
    end

    def digits_after_international_dialing_prefix
      diagnostic_countries.each do |country|
        data = Phonelib.phone_data[country]
        next unless data && data[Core::INTERNATIONAL_PREFIX]

        prefix = sanitized.match(cr("^(?:#{data[Core::INTERNATIONAL_PREFIX]})"))
        return sanitized[prefix[0].length..-1] if prefix
      end
      nil
    end

    def diagnostic_countries
      Array(@passed_country || Phonelib.default_country).compact.map do |country|
        normalize_passed_country(country)
      end
    end

    def country_calling_code_for(digits)
      (1..3).map { |length| digits[0, length] }.find do |code|
        Phonelib.data_by_country_codes.key?(code)
      end
    end

    def policy_validation_errors(options, possible)
      errors = []
      allowed_types = normalize_validation_values(options[:types]) { |type| type.to_sym }
      matched_types = possible ? possible_types : types
      expanded_types = matched_types.dup
      if expanded_types.include?(Core::FIXED_OR_MOBILE)
        expanded_types += Core::FIXED_LINE_OR_MOBILE_ARRAY
      end
      if !options[:types].nil? && (expanded_types & allowed_types).empty?
        errors << ValidationError.new(
          :type_not_allowed,
          allowed_types: allowed_types,
          matched_types: matched_types
        )
      end

      allowed_countries = normalize_validation_values(options[:countries]) do |country|
        country.to_s.upcase
      end
      matched_countries = possible ? possible_policy_countries : valid_countries
      if !options[:countries].nil? && (matched_countries & allowed_countries).empty?
        errors << ValidationError.new(
          :country_not_allowed,
          allowed_countries: allowed_countries,
          matched_countries: matched_countries
        )
      end

      if options.fetch(:extensions, true) == false && !extension.to_s.empty?
        errors << ValidationError.new(:extension_not_allowed, extension_present: true)
      end
      errors
    end

    def possible_policy_countries
      return countries if countries.any?

      context = diagnostic_number_context
      context ? [context.last[:id]].compact : []
    end

    def normalize_validation_values(value)
      Array(value).map { |item| yield(item) }.uniq.freeze
    end
  end
end
