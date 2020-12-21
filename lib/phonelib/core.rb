module Phonelib
  # main module that includes all basic data and methods
  module Core
    # @private variable will include hash with data for validation
    @@phone_data = nil

    # getter for phone data for other modules of gem, can be used outside
    # @return [Hash] all data for phone parsing
    def phone_data
      @@phone_data ||= load_data.freeze
    end

    # @private used to cache frequently-used regular expressions
    @@phone_regexp_cache = {}

    # @private getter for phone regexp cache (internal use only)
    def phone_regexp_cache
      @@phone_regexp_cache
    end

    # @private variable for storing geo/carrier/timezone data
    @@phone_ext_data = nil

    # @private getter for extended phone data
    def phone_ext_data
      @@phone_ext_data ||= load_ext_data.freeze
    end

    # @private default country for parsing variable setting
    @@default_country = nil

    # getter method for default_country variable
    # @return [String|nil] Default country set for parsing or nil
    def default_country
      @@default_country
    end

    # setter method for default_country variable
    # @param country [String|Symbol] default country ISO2 code used for parsing
    # @return [String|nil] Default country set for parsing or nil
    def default_country=(country)
      @@default_country = country
    end

    # @private extension separator
    @@extension_separator = ';'

    # getter method for extension_separator variable
    # @return [String] Default extension separator used for formatting
    def extension_separator
      @@extension_separator
    end

    # setter method for extension_separator variable
    # @param separator [String] extension separator used for formatting
    # @return [String] Default extension separator used for formatting
    def extension_separator=(separator)
      @@extension_separator = separator
    end

    # @private extension separator symbols for parsing
    @@extension_separate_symbols = '#;'

    # getter method for extension_separate_symbols variable
    # @return [String] Default extension separator symbols used for parsing
    def extension_separate_symbols
      @@extension_separate_symbols
    end

    # setter method for extension_separate_symbols variable
    # @param separator [String] extension separator symbols used for parsing
    # @return [String] Default extension separator symbols used for parsing
    def extension_separate_symbols=(separator)
      @@extension_separate_symbols = separator
    end

    # @private flag identifies whether to use special phone types, \
    #   like short code
    @@parse_special = false

    # getter for flag for special phone types parsing
    # @return [Boolean] Flag defines whether to parse special phone types
    def parse_special
      @@parse_special
    end

    # setter for flag for special phone types parsing
    # @param special [Boolean] parse special phone types value
    # @return [Boolean] Flag defines whether to parse special phone types
    def parse_special=(special)
      @@parse_special = special
    end

    # @private strict check for validator, doesn't sanitize number
    @@strict_check = false

    # getter for strict check flag
    # @return [Boolean] Flag defines whether to do strict parsing check
    def strict_check
      @@strict_check
    end

    # setter for strict check flag
    # @param strict [Boolean] make a strict parsing or not
    # @return [Boolean] Flag defines whether to do strict parsing check
    def strict_check=(strict)
      @@strict_check = strict
    end

    # @private sanitizing regex, matching symbols will get removed from parsed number, must be string
    @@sanitize_regex = '[^0-9]+'

    # getter for sanitize regex
    # @return [String] regex of symbols to wipe from parsed number
    def sanitize_regex
      @@sanitize_regex
    end

    # setter for sanitize regex
    # @param regex [String] symbols to wipe from parsed number
    # @return [String] regex of symbols to wipe from parsed number
    def sanitize_regex=(regex)
      @@sanitize_regex = regex.is_a?(String) ? regex : regex.to_s
    end

    # @private strict double prefix check for validator, doesn't sanitize number
    @@strict_double_prefix_check = false

    # getter for strict double prefix check flag
    # @return [Boolean] Flag defines whether to do strict double prefix parsing check
    def strict_double_prefix_check
      @@strict_double_prefix_check
    end

    # setter for strict double prefix check flag
    # @param strict [Boolean] make a strict double prefix parsing or not
    # @return [Boolean] Flag defines whether to do strict double prefix parsing check
    def strict_double_prefix_check=(strict)
      @@strict_double_prefix_check = strict
    end

    @@override_phone_data = nil
    # setter for data file to use
    def override_phone_data=(file_path)
      @@override_phone_data = file_path
    end

    def override_phone_data
      @@override_phone_data
    end

    @@vanity_conversion = false
    # setter for vanity phone numbers chars replacement
    def vanity_conversion=(value)
      @@vanity_conversion = value
    end

    def vanity_conversion
      @@vanity_conversion
    end

    # gem constants definition

    # @private Main data file
    FILE_MAIN_DATA = 'data/phone_data.dat'
    # @private Extended data file
    FILE_EXT_DATA = 'data/extended_data.dat'

    # constants for phone types

    # Validation patterns keys constants
    # @private General pattern for country key
    GENERAL = :general_desc
    # @private Freephone line pattern key
    PREMIUM_RATE = :premium_rate
    # @private Freephone line pattern key
    TOLL_FREE = :toll_free
    # @private Shared cost pattern key. The cost of this call is shared
    # between caller and recipient, and is hence typically less than
    # PREMIUM_RATE calls
    SHARED_COST = :shared_cost
    # @private VoIP pattern key. This includes TSoIP (Telephony Service over IP)
    VOIP = :voip
    # @private A personal number is associated with a particular person,
    # and may be routed to either a MOBILE or FIXED_LINE number.
    PERSONAL_NUMBER = :personal_number
    # @private Pager phone number pattern key
    PAGER = :pager
    # @private Used for 'Universal Access Numbers' or 'Company Numbers'.
    #   They may be further routed to specific offices, but allow one number
    #   to be used for a company.
    UAN = :uan
    # @private Used for 'Voice Mail Access Numbers'.
    VOICEMAIL = :voicemail
    # @private Fixed line pattern key
    FIXED_LINE = :fixed_line
    # @private Mobile phone number pattern key
    MOBILE = :mobile
    # @private In case MOBILE and FIXED patterns are the same,
    #   this type is returned
    FIXED_OR_MOBILE = :fixed_or_mobile
    # @private Short code
    SHORT_CODE = :short_code
    # @private emergency numbers
    EMERGENCY = :emergency
    # @private carrier specific type
    CARRIER_SPECIFIC = :carrier_specific
    # @private SMS Services only type
    SMS_SERVICES = :sms_services
    # @private expendad emergency type
    EXPANDED_EMERGENCY = :expanded_emergency
    # @private no international dialling type
    NO_INTERNATIONAL_DIALING = :no_international_dialling
    # @private carrier services type
    CARRIER_SERVICES = :carrier_services
    # @private directory services
    DIRECTORY_SERVICES = :directory_services
    # @private standard rate type
    STANDARD_RATE = :standard_rate
    # @private carrier selection codes
    CARRIER_SELECTION_CODES = :carrier_selection_codes
    # @private area code optional type
    AREA_CODE_OPTIONAL = :area_code_optional

    # Internal use keys for validations
    # @private Valid regex pattern key
    VALID_PATTERN = :national_number_pattern
    # @private Possible regex pattern key
    POSSIBLE_PATTERN = :possible_number_pattern
    # @private National prefix key
    NATIONAL_PREFIX = :national_prefix
    # @private National prefix for parsing key
    NATIONAL_PREFIX_FOR_PARSING = :national_prefix_for_parsing
    # @private National prefix transform rule key
    NATIONAL_PREFIX_TRANSFORM_RULE = :national_prefix_transform_rule
    # @private National prefix rule key
    NATIONAL_PREFIX_RULE = :national_prefix_formatting_rule
    # @private Country code key
    COUNTRY_CODE = :country_code
    # @private Leading digits key
    LEADING_DIGITS = :leading_digits
    # @private International prefix key
    INTERNATIONAL_PREFIX = :international_prefix
    # @private Main country for code key
    MAIN_COUNTRY_FOR_CODE = :main_country_for_code
    # @private Double country prefix flag key
    DOUBLE_COUNTRY_PREFIX_FLAG = :double_prefix
    # @private Types key
    TYPES = :types
    # @private Formats key
    FORMATS = :formats
    # @private Pattern key
    PATTERN = :pattern
    # @private Short key
    SHORT = :short

    # @private Plus sign
    PLUS_SIGN = '+'.freeze

    # @private vanity numbers 4 keys letters
    VANITY_4_LETTERS_KEYS_REGEX = /[SVYZ]/.freeze

    # @private Area code possible types
    AREA_CODE_TYPES = [FIXED_LINE, FIXED_OR_MOBILE, MOBILE].freeze

    # @private Area code countries for mobile type
    AREA_CODE_MOBILE_COUNTRIES = %w(AR MX BR).freeze

    # @private Area code mobile phone token
    AREA_CODE_MOBILE_TOKENS = {
      'MX' => '1',
      'AR' => '9'
    }.freeze

    # @private Default number formatting data hash
    DEFAULT_NUMBER_FORMAT = {
      pattern: '(\\d+)(\\d{3})(\\d{4})',
      format: '$1 $2 $3'
    }.freeze

    # @private hash of all phone types with human representation
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
    }.freeze

    # @private short codes types keys
    SHORT_CODES = [
      :short_code, :emergency, :carrier_specific, :sms_services,
      :expanded_emergency, :no_international_dialling, :carrier_services,
      :directory_services, :standard_rate, :carrier_selection_codes,
      :area_code_optional
    ].freeze

    # @private Extended data prefixes hash key
    EXT_PREFIXES = :prefixes
    # @private Extended data geo names array key
    EXT_GEO_NAMES = :geo_names
    # @private Extended data country names array key
    EXT_COUNTRY_NAMES = :country_names
    # @private Extended data timezones array key
    EXT_TIMEZONES = :timezones
    # @private Extended data carriers array key
    EXT_CARRIERS = :carriers
    # @private Extended data key for geoname in prefixes hash
    EXT_GEO_NAME_KEY = :g
    # @private Extended data key for timezone in prefixes hash
    EXT_TIMEZONE_KEY = :t
    # @private Extended data key for carrier in prefixes hash
    EXT_CARRIER_KEY = :c

    # method for parsing phone number.
    # On first run fills @@phone_data with data present in yaml file
    # @param phone [String] the phone number to be parsed
    # @param passed_country [nil|String|Symbol] country for phone parsing
    # @return [Phonelib::Phone] parsed phone entity
    def parse(phone, passed_country = nil)
      Phonelib::Phone.new phone, passed_country
    end

    # method checks if passed phone number is valid
    # @param phone_number [String] the phone number to be parsed
    # @return [Boolean] phone valid or not
    def valid?(phone_number)
      parse(phone_number).valid?
    end

    # method checks if passed phone number is invalid
    # @param phone_number [String] the phone number to be parsed
    # @return [Boolean] phone invalid or not
    def invalid?(phone_number)
      parse(phone_number).invalid?
    end

    # method checks if passed phone number is possible
    # @param phone_number [String] the phone number to be parsed
    # @return [Boolean] phone possible or not
    def possible?(phone_number)
      parse(phone_number).possible?
    end

    # method checks if passed phone number is impossible
    # @param phone_number [String] the phone number to be parsed
    # @return [Boolean] phone impossible or not
    def impossible?(phone_number)
      parse(phone_number).impossible?
    end

    # method checks if passed phone number is valid for provided country
    # @param phone_number [String] the phone number to be parsed
    # @param country [String] ISO2 country code for phone parsing
    # @return [Boolean] phone valid for specified country or not
    def valid_for_country?(phone_number, country)
      parse(phone_number, country).valid_for_country?(country)
    end

    # method checks if passed phone number is invalid for provided country
    # @param phone_number [String] the phone number to be parsed
    # @param country [String] ISO2 country code for phone parsing
    # @return [Boolean] phone invalid for specified country or not
    def invalid_for_country?(phone_number, country)
      parse(phone_number, country).invalid_for_country?(country)
    end

    private

    # @private Load data file into memory
    def load_data
      data_file = "#{File.dirname(__FILE__)}/../../#{FILE_MAIN_DATA}"
      default_data = Marshal.load(File.binread(data_file))
      if override_phone_data
        override_data_file = Marshal.load(File.binread(override_phone_data))
        default_data.merge!(override_data_file)
      end
      default_data
    end

    # @private Load extended data file into memory
    def load_ext_data
      data_file = "#{File.dirname(__FILE__)}/../../#{FILE_EXT_DATA}"
      Marshal.load(File.binread(data_file))
    end
  end
end
