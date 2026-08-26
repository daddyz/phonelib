# frozen_string_literal: true

module Phonelib
  # Immutable outcome of validating a parsed phone against a rule set.
  class ValidationResult
    attr_reader :phone, :errors, :possibility

    def initialize(phone, errors, possibility)
      @phone = phone
      @errors = Errors.new(errors)
      @possibility = possibility
      freeze
    end

    def valid?
      errors.empty?
    end

    def invalid?
      !valid?
    end

    def error
      errors.first
    end
  end
end
