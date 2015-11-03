module Phonelib
  # main module that includes all basic data and methods
  module Core
    # variable will include hash with data for validation
    @@phone_data = nil

    # getter for phone data for other modules of gem, can be used outside
    def phone_data
      @@phone_data ||= load_data.freeze
    end

    # used to cache frequently-used regular expressions
    @@phone_regexp_cache = {}

    # getter for phone regexp cache (internal use only)
    def phone_regexp_cache
      @@phone_regexp_cache
    end

    # variable for storing geo/carrier/timezone data
    @@phone_ext_data = nil

    # getter for extended phone data
    def phone_ext_data
      @@phone_ext_data ||= load_ext_data.freeze
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

    # extension separator
    @@extension_separator = ';'

    # getter method for extension_separator variable
    def extension_separator
      @@extension_separator
    end

    # setter method for extension_separator variable
    def extension_separator=(separator)
      @@extension_separator = separator
    end

    # extension separator symbols for parsing
    @@extension_separate_symbols = '#;'

    # getter method for extension_separate_symbols variable
    def extension_separate_symbols
      @@extension_separate_symbols
    end

    # setter method for extension_separate_symbols variable
    def extension_separate_symbols=(separator)
      @@extension_separate_symbols = separator
    end

    # flag identifies whether to use special phone types, like short code
    @@parse_special = false

    # getter for flag for special phone types parsing
    def parse_special
      @@parse_special
    end

    # setter for flag for special phone types parsing
    def parse_special=(special)
      @@parse_special = special
    end

    # gem constants definition

    # Main data file
    FILE_MAIN_DATA = 'data/phone_data.dat'
    # Extended data file
    FILE_EXT_DATA = 'data/extended_data.dat'

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
    # Short code
    SHORT_CODE = :short_code
    # emergency numbers
    EMERGENCY = :emergency
    # carrier specific type
    CARRIER_SPECIFIC = :carrier_specific
    # SMS Services only type
    SMS_SERVICES = :sms_services
    # expendad emergency type
    EXPANDED_EMERGENCY = :expanded_emergency
    # no international dialling type
    NO_INTERNATIONAL_DIALING = :no_international_dialling
    # carrier services type
    CARRIER_SERVICES = :carrier_services
    # directory services
    DIRECTORY_SERVICES = :directory_services
    # standard rate type
    STANDARD_RATE = :standard_rate
    # carrier selection codes
    CARRIER_SELECTION_CODES = :carrier_selection_codes
    # area code optional type
    AREA_CODE_OPTIONAL = :area_code_optional

    # Internal use keys for validations
    # Valid regex pattern key
    VALID_PATTERN = :national_number_pattern
    # Possible regex pattern key
    POSSIBLE_PATTERN = :possible_number_pattern
    # National prefix key
    NATIONAL_PREFIX = :national_prefix
    # National prefix for parsing key
    NATIONAL_PREFIX_FOR_PARSING = :national_prefix_for_parsing
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
    # Double country prefix flag key
    DOUBLE_COUNTRY_PREFIX_FLAG = :double_prefix
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
      fixed_or_mobile: 'Fixed Line or Mobile',
      short_code: 'Short code',
      emergency: 'Emergency services',
      carrier_specific: 'Carrier specific number',
      sms_services: 'SMS Services only phone',
      expanded_emergency: 'Expanded emergency',
      no_international_dialling: 'No International Dialing phone',
      carrier_services: 'Carrier Services',
      directory_services: 'Directory Services',
      standard_rate: 'Standard Rate Destination',
      carrier_selection_codes: 'Carrier Selection codes',
      area_code_optional: 'Are code optional'
    }

    # short codes types keys
    SHORT_CODES = [
        :short_code, :emergency, :carrier_specific, :sms_services,
        :expanded_emergency, :no_international_dialling, :carrier_services,
        :directory_services, :standard_rate, :carrier_selection_codes,
        :area_code_optional
    ]

    # Extended data prefixes hash key
    EXT_PREFIXES = :prefixes
    # Extended data geo names array key
    EXT_GEO_NAMES = :geo_names
    # Extended data timezones array key
    EXT_TIMEZONES = :timezones
    # Extended data carriers array key
    EXT_CARRIERS = :carriers
    # Extended data key for geoname in prefixes hash
    EXT_GEO_NAME_KEY = :g
    # Extended data key for timezone in prefixes hash
    EXT_TIMEZONE_KEY = :t
    # Extended data key for carrier in prefixes hash
    EXT_CARRIER_KEY = :c

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
      data_file = "#{File.dirname(__FILE__)}/../../#{FILE_MAIN_DATA}"
      Marshal.load(File.binread(data_file))
    end

    # Load extended data file into memory
    def load_ext_data
      data_file = "#{File.dirname(__FILE__)}/../../#{FILE_EXT_DATA}"
      Marshal.load(File.binread(data_file))
    end
  end
end
