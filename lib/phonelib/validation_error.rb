# frozen_string_literal: true

module Phonelib
  # A framework-independent, immutable phone validation diagnostic.
  class ValidationError
    DEFAULT_MESSAGES = {
      not_a_number: 'is not a phone number',
      invalid_country_code: 'has an invalid country calling code',
      too_short: 'is too short',
      too_long: 'is too long',
      invalid_length: 'has an invalid length',
      not_possible: 'is not a possible phone number',
      invalid: 'is not a valid phone number',
      type_not_allowed: 'has a phone type that is not allowed',
      country_not_allowed: 'is from a country that is not allowed',
      extension_not_allowed: 'must not include an extension'
    }.freeze

    attr_reader :code, :details

    def initialize(code, details = {})
      @code = DEFAULT_MESSAGES.keys.find { |key| key.to_s == code.to_s }
      unless @code
        raise ArgumentError, "unknown validation error code: #{code}"
      end
      @details = immutable_copy(details)
      freeze
    end

    def i18n_key
      "phonelib.errors.#{code}".to_sym
    end

    def message(translator = nil)
      default = DEFAULT_MESSAGES.fetch(code, code.to_s.tr('_', ' '))
      return default unless translator

      translator.call(i18n_key, **{ default: default }.merge(details))
    end

    private

    def immutable_copy(value)
      case value
      when Hash
        value.each_with_object({}) do |(key, item), copy|
          copy[key] = immutable_copy(item)
        end.freeze
      when Array
        value.map { |item| immutable_copy(item) }.freeze
      when String
        value.dup.freeze
      else
        value
      end
    end
  end
end
