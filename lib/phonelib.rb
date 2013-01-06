module Phonelib
  @@phone_data = nil

  extend Module.new do

    def valid?(phone_number)
      real_phone = phone_number.gsub(/[^0-9]+/, '')
      return false if real_phone.blank?

      analyzed_data = analyze_phone(phone_number)
      pp analyzed_data
      analyzed_data.keep_if {|country, data| data[:valid] }.present?
    end

    def invalid?(phone_number)
      !valid?(phone_number)
    end

    def possible?(phone_number)
      real_phone = phone_number.gsub(/[^0-9]+/, '')
      return false if real_phone.blank?

      analyzed_data = analyze_phone(phone_number)
      analyzed_data.keep_if {|country, data| data[:possible] }.present?
    end

    def impossible?(phone_number)
      !possible?(phone_number)
    end

  private
    def analyze_phone(phone)
      @@phone_data ||= YAML.load_file('data/phone_data.yml')

      possible_countries = @@phone_data.select do |data|
        phone.start_with?(data[:countryCode])
      end

      responses = {}

      possible_countries.each do |country_data|
        next unless country_data[:types].present?

        number = phone[country_data[:countryCode].length..phone.length]

        types = {}
        country_data[:types].each do |type, patterns|
          valid = number.match(/^(?:#{patterns[:nationalNumberPattern]})$/)
          possible = number.match(/^(?:#{patterns[:possibleNumberPattern]})$/)

          types[type] = {
            valid: (valid && valid.to_s.length == number.length),
            possible: (possible && possible.to_s.length == number.length),
          }
        end

        responses[country_data[:id]] = {
          valid: types.select {|type, val| val[:valid].present? }.present?,
          possible: types.select {|type, val| val[:possible].present? }.present?,
          types: types
        }
      end
      responses
    end


  end
end
