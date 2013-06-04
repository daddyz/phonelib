module Phonelib
  # main module that includes all basic data and methods
  module Core
    # variable will include hash with data for validation
    @@phone_data = nil

    # gem constants definition
    # constants for phone types

    # Validation patterns keys constants
    # General pattern for country key
    GENERAL = :generalDesc
    # Freephone line pattern key
    PREMIUM_RATE = :premiumRate
    # Freephone line pattern key
    TOLL_FREE = :tollFree
    # Shared cost pattern key. The cost of this call is shared between caller
    # and recipient, and is hence typically less than PREMIUM_RATE calls
    SHARED_COST = :sharedCost
    # Voice over IP pattern key. This includes TSoIP (Telephony Service over IP)
    VOIP = :voip
    # A personal number is associated with a particular person, and may be
    # routed to either a MOBILE or FIXED_LINE number.
    PERSONAL_NUMBER = :personalNumber
    # Pager phone number pattern key
    PAGER = :pager
    # Used for 'Universal Access Numbers' or 'Company Numbers'. They may be
    # further routed to specific offices, but allow one number to be used for a
    # company.
    UAN = :uan
    # Used for 'Voice Mail Access Numbers'.
    VOICEMAIL = :voicemail
    # Fixed line pattern key
    FIXED_LINE = :fixedLine
    # Mobile phone number pattern key
    MOBILE = :mobile
    # Emergency phone number pattern key
    EMERGENCY = :emergency
    # Short code phone number pattern key
    SHORT_CODE = :shortCode
    # In case MOBILE and FIXED patterns are the same, this type is returned
    FIXED_OR_MOBILE = :fixedOrMobile

    # Internal use keys for validations
    # Valid regex pattern key
    VALID_PATTERN = :nationalNumberPattern
    # Possible regex pattern key
    POSSIBLE_PATTERN = :possibleNumberPattern
    # National prefix key
    NATIONAL_PREFIX = :nationalPrefix
    # National prefix rule key
    NATIONAL_PREFIX_RULE = :nationalPrefixFormattingRule
    # Country code key
    COUNTRY_CODE = :countryCode

    # Default number formatting data hash
    DEFAULT_NUMBER_FORMAT = {
      pattern: "(\\d+)(\\d{3})(\\d{4})",
      format: "$1 $2 $3"
    }

    # hash of all phone types with human representation
    TYPES = {
      generalDesc: 'General Pattern',
      premiumRate: 'Premium Rate',
      tollFree: 'Toll Free',
      sharedCost: 'Shared Cost',
      voip: 'VoIP',
      personalNumber: 'Personal Number',
      pager: 'Pager',
      uan: 'UAN',
      voicemail: 'VoiceMail',
      fixedLine: 'Fixed Line',
      mobile: 'Mobile',
      emergency: 'Emergency',
      shortCode: 'Short Code',
      fixedOrMobile: 'Fixed Line or Mobile'
    }

    # array of types not included for validation check in cycle
    NOT_FOR_CHECK = [
      :generalDesc, :emergency, :shortCode, :fixedLine, :mobile, :fixedOrMobile
    ]

    # method for parsing phone number.
    # On first run fills @@phone_data with data present in yaml file
    def parse(phone, country = nil)
      require 'yaml'
      data_file = File.dirname(__FILE__) + '/../../data/phone_data.yml'
      @@phone_data ||= YAML.load_file(data_file)
      if country.nil?
        Phonelib::Phone.new(phone, @@phone_data)
      else
        detected = @@phone_data.detect { |data| data[:id] == country }
        if !!detected
          phone = convert_phone_to_e164(phone,
                                        detected[:countryCode],
                                        detected[:nationalPrefix])
        end
        Phonelib::Phone.new(phone, [detected])
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
      country = country.to_s.upcase
      parse(phone_number, country).valid_for_country?(country)
    end

    # method checks if passed phone number is invalid for provided country
    def invalid_for_country?(phone_number, country)
      country = country.to_s.upcase
      parse(phone_number, country).invalid_for_country?(country)
    end

    private
    def convert_phone_to_e164(phone, prefix, national_prefix)
      return phone if phone.start_with?(prefix)
      if !!national_prefix && phone.start_with?(national_prefix)
        phone = phone[1..phone.length]
      end
      prefix + phone
    end
  end
end
