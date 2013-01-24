module Phonelib
  # main module that includes all basic data and methods
  module Core
    # variable will include hash with data for validation
    @@phone_data = nil

    # gem constants definition
    # constants for phone types
    GENERAL = :generalDesc
    PREMIUM_RATE = :premiumRate
    TOLL_FREE = :tollFree
    SHARED_COST = :sharedCost
    VOIP = :voip
    PERSONAL_NUMBER = :personalNumber
    PAGER = :pager
    UAN = :uan
    VOICEMAIL = :voicemail
    FIXED_LINE = :fixedLine
    MOBILE = :mobile
    EMERGENCY = :emergency
    SHORT_CODE = :shortCode
    FIXED_OR_MOBILE = :fixedOrMobile

    # hash of all possible types with description
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

    # method for parsing phone number
    # on first run fills @@phone_data with data present in yaml file
    def parse(phone)
      require 'yaml'
      data_file = File.dirname(__FILE__) + '/../../data/phone_data.yml'
      @@phone_data ||= YAML.load_file(data_file)
      Phonelib::Phone.new(phone, @@phone_data)
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
      parse(phone_number).valid_for_country?(country)
    end

    # method checks if passed phone number is invalid for provided country
    def invalid_for_country?(phone_number, country)
      parse(phone_number).invalid_for_country?(country)
    end
  end
end