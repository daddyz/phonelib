module Phonelib
  module Core
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

    def valid_and_possible?(number, regexes)
      national_match = number.match(/^(?:#{regexes[:nationalNumberPattern]})$/)
      possible_match = number.match(/^(?:#{regexes[:possibleNumberPattern]})$/)

      national_match && possible_match &&
          national_match.to_s.length == number.length &&
          possible_match.to_s.length == number.length
    end

    def get_number_type(number, data)
      return nil unless data[self::GENERAL].present?
      return nil unless valid_and_possible?(number, data[self::GENERAL])

      self::TYPES.keys.except(self::NOT_FOR_CHECK).each do |type|
        next unless data[type].present?
        return type if valid_and_possible?(number, data[type])
      end

      if valid_and_possible?(number, data[self::FIXED_LINE])
        if data[self::FIXED_LINE] == data[self::MOBILE] ||
            valid_and_possible?(number, data[self::MOBILE])

          return self::FIXED_OR_MOBILE
        else
          return self::FIXED_LINE
        end
      elsif valid_and_possible?(number, data[self::MOBILE])
        return self::MOBILE
      end

      nil
    end
  end




end