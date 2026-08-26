# frozen_string_literal: true

module Phonelib
  # Read-only collection of phone validation errors.
  class Errors
    include Enumerable

    def initialize(errors = [])
      @errors = errors.dup.freeze
      freeze
    end

    def each(&block)
      @errors.each(&block)
    end

    def empty?
      @errors.empty?
    end

    def size
      @errors.size
    end

    def first
      @errors.first
    end

    def details
      @errors.map { |error| { error: error.code }.merge(error.details).freeze }.freeze
    end

    def messages(options = {})
      translator = options.is_a?(Hash) ? options[:translator] : options
      @errors.map { |error| error.message(translator) }.freeze
    end

    def full_messages(options = {})
      messages(options)
    end
  end
end
