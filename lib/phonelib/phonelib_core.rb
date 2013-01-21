module Phonelib
  module Core

    @@phone_data = nil

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

    NOT_FOR_CHECK = [
      :generalDesc, :emergency, :shortCode, :fixedLine, :mobile, :fixedOrMobile
    ]

    def parse(phone)
      data_file = File.dirname(__FILE__) + '/../../data/phone_data.yml'
      @@phone_data ||= YAML.load_file(data_file)
      Phonelib::Phone.new(phone, @@phone_data)
    end

    def valid?(phone_number)
      parse(phone_number).valid?
    end

    def invalid?(phone_number)
      parse(phone_number).invalid?
    end

    def possible?(phone_number)
      parse(phone_number).possible?
    end

    def impossible?(phone_number)
      parse(phone_number).impossible?
    end

    def valid_for_country?(phone_number, country)
      parse(phone_number).valid_for_country?(country)
    end

    def invalid_for_country?(phone_number, country)
      parse(phone_number).invalid_for_country?(country)
    end
  end
end