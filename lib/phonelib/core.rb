module Phonelib
  # main module that includes all basic data and methods
  module Core
    # variable will include hash with data for validation
    @@phone_data = nil

    # default country for parsing variable setting
    @@default_country = nil

    # getter method for default_country variable
    def default_country
      @@default_country
    end

    # setter method for default_country variable
    def default_country=(country)
      @@default_country = country
    end

    # gem constants definition
    # constants for phone types

    # Validation patterns keys constants
    # General pattern for country key
    GENERAL = :general_desc
    # Freephone line pattern key
    PREMIUM_RATE = :premium_rate
    # Freephone line pattern key
    TOLL_FREE = :toll_free
    # Shared cost pattern key. The cost of this call is shared between caller
    # and recipient, and is hence typically less than PREMIUM_RATE calls
    SHARED_COST = :shared_cost
    # VoIP pattern key. This includes TSoIP (Telephony Service over IP)
    VOIP = :voip
    # A personal number is associated with a particular person, and may be
    # routed to either a MOBILE or FIXED_LINE number.
    PERSONAL_NUMBER = :personal_number
    # Pager phone number pattern key
    PAGER = :pager
    # Used for 'Universal Access Numbers' or 'Company Numbers'. They may be
    # further routed to specific offices, but allow one number to be used for a
    # company.
    UAN = :uan
    # Used for 'Voice Mail Access Numbers'.
    VOICEMAIL = :voicemail
    # Fixed line pattern key
    FIXED_LINE = :fixed_line
    # Mobile phone number pattern key
    MOBILE = :mobile
    # In case MOBILE and FIXED patterns are the same, this type is returned
    FIXED_OR_MOBILE = :fixed_or_mobile

    # Internal use keys for validations
    # Valid regex pattern key
    VALID_PATTERN = :national_number_pattern
    # Possible regex pattern key
    POSSIBLE_PATTERN = :possible_number_pattern
    # National prefix key
    NATIONAL_PREFIX = :national_prefix
    # National prefix rule key
    NATIONAL_PREFIX_RULE = :national_prefix_formatting_rule
    # Country code key
    COUNTRY_CODE = :country_code
    # Leading digits key
    LEADING_DIGITS = :leading_digits
    # International prefix key
    INTERNATIONAL_PREFIX = :international_prefix
    # Main country for code key
    MAIN_COUNTRY_FOR_CODE = :main_country_for_code
    # Types key
    TYPES = :types
    # Formats key
    FORMATS = :formats
    # Pattern key
    PATTERN = :pattern

    # Default number formatting data hash
    DEFAULT_NUMBER_FORMAT = {
      pattern: '(\\d+)(\\d{3})(\\d{4})',
      format: '$1 $2 $3'
    }

    # hash of all phone types with human representation
    TYPES_DESC = {
      general_desc: 'General Pattern',
      premium_rate: 'Premium Rate',
      toll_free: 'Toll Free',
      shared_cost: 'Shared Cost',
      voip: 'VoIP',
      personal_number: 'Personal Number',
      pager: 'Pager',
      uan: 'UAN',
      voicemail: 'VoiceMail',
      fixed_line: 'Fixed Line',
      mobile: 'Mobile',
      fixed_or_mobile: 'Fixed Line or Mobile'
    }

    # method for parsing phone number.
    # On first run fills @@phone_data with data present in yaml file
    def parse(phone, passed_country = nil)
      load_data

      country = country_or_default_country(passed_country)
      if phone.nil? || country.nil?
        # has to return instance of Phonelib::Phone even if no phone passed
        Phonelib::Phone.new(phone, @@phone_data)
      else
        detected = detect_and_parse_by_country(phone, country)
        if passed_country.nil? && @@default_country && detected.invalid?
          Phonelib::Phone.new(phone, @@phone_data)
        else
          detected
        end
      end
    end

    # method checks if passed phone number is valid
    def valid?(phone_number)
      parse(phone_number).valid?
    end

    # method checks if passed phone number is invalid
    def invalid?(phone_number)
      parse(phone_number).invalid?
    end

    # method checks if passed phone number is possible
    def possible?(phone_number)
      parse(phone_number).possible?
    end

    # method checks if passed phone number is impossible
    def impossible?(phone_number)
      parse(phone_number).impossible?
    end

    # method checks if passed phone number is valid for provided country
    def valid_for_country?(phone_number, country)
      parse(phone_number, country).valid_for_country?(country)
    end

    # method checks if passed phone number is invalid for provided country
    def invalid_for_country?(phone_number, country)
      parse(phone_number, country).invalid_for_country?(country)
    end

    private

    # Load data file into memory
    def load_data
      data_file = File.dirname(__FILE__) + '/../../data/phone_data.dat'
      @@phone_data ||= Marshal.load(File.read(data_file))
    end

    # Get country that was provided or default country in needable format
    def country_or_default_country(country)
      country = country || @@default_country
      country.to_s.upcase unless country.nil?
    end

    # Get Phone instance for provided phone with country specified
    def detect_and_parse_by_country(phone, country)
      detected = @@phone_data.find { |data| data[:id] == country }
      if detected
        phone = convert_phone_to_e164(phone, detected)
        if phone[0] == '+'
          Phonelib::Phone.new(phone, @@phone_data)
        else 
          Phonelib::Phone.new(phone, [detected])
        end
      end
    end

    # Create phone representation in e164 format
    def convert_phone_to_e164(phone, data) #prefix, national_prefix)
      rx = []
      rx << "(#{data[Core::INTERNATIONAL_PREFIX]})?"
      rx << "(#{data[Core::COUNTRY_CODE]})?"
      rx << "(#{data[Core::NATIONAL_PREFIX]})?"
      rx << "(#{data[Core::TYPES][Core::GENERAL][Core::VALID_PATTERN]})"

      match = phone.gsub('+', '').match(/^#{rx.join}$/)
      if match
        national_start = 1.upto(3).map {|i| match[i].to_s.length}.inject(:+)
        "#{data[Core::COUNTRY_CODE]}#{phone[national_start..-1]}"
      else
        phone.sub(/^#{data[Core::INTERNATIONAL_PREFIX]}/, '+')
      end
    end
  end
end
