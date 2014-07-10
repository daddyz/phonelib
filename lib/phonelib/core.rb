module Phonelib
  # main module that includes all basic data and methods
  module Core
    # variable will include hash with data for validation
    @@phone_data = nil

    # getter for phone data for other modules of gem, can be used outside
    def phone_data
      @@phone_data ||= load_data
    end

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
      Phonelib::Phone.new phone, passed_country
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
      Marshal.load(File.binread(data_file))
    end
  end
end
