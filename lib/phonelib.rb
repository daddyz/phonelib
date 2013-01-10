module Phonelib
  autoload :Core, 'phonelib/phonelib_core'

  @@phone_data = nil

  extend Module.new {
    include Core

    def valid?(phone_number)
      return false unless real_phone = sanitize_phone(phone_number)

      analyzed_data = analyze_phone(real_phone)
      analyzed_data.keep_if {|country, data| data[:valid].present? }.present?
    end

    def invalid?(phone_number)
      !valid?(phone_number)
    end

    def possible?(phone_number)
      return false unless real_phone = sanitize_phone(phone_number)

      analyzed_data = analyze_phone(real_phone)
      analyzed_data.keep_if {|country, data| data[:possible].present? }.present?
    end

    def impossible?(phone_number)
      !possible?(phone_number)
    end

    def valid_for_country?(phone_number, country)
      return false unless real_phone = sanitize_phone(phone_number)
      analyzed_data = analyze_phone(real_phone)
      analyzed_data.keep_if {|iso2, data| country == iso2 &&
                                          data[:valid].present? }.present?
    end

    def invalid_for_country?(phone_number, country)
      return false unless real_phone = sanitize_phone(phone_number)
      analyzed_data = analyze_phone(real_phone)
      analyzed_data.keep_if {|iso2, data| country != iso2 &&
          data[:valid].present? }.present?
    end


  private
    def sanitize_phone(phone_number)
      real_phone = phone_number.gsub(/[^0-9]+/, '')
    end

    def analyze_phone(phone)
      @@phone_data ||= YAML.load_file('data/phone_data.yml')

      possible_countries = @@phone_data.select do |data|
        phone.start_with?(data[:countryCode])
      end

      responses = {}

      possible_countries.each do |country_data|
        next unless country_data[:types].present?

        number = phone[country_data[:countryCode].length..phone.length]
        responses[country_data[:id]] =
            get_all_number_types(number, country_data[:types])
      end
      responses
    end


  }
end
