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

    def number_valid_and_possible?(number, regexes)
      national_match = number.match(/^(?:#{regexes[:nationalNumberPattern]})$/)
      possible_match = number.match(/^(?:#{regexes[:possibleNumberPattern]})$/)

      national_match && possible_match &&
          national_match.to_s.length == number.length &&
          possible_match.to_s.length == number.length
    end

    def number_possible?(number, regexes)
      possible_match = number.match(/^(?:#{regexes[:possibleNumberPattern]})$/)
      possible_match && possible_match.to_s.length == number.length
    end

    def get_all_number_types(number, data)
      response = {valid: [], possible: []}

      return response unless data[Core::GENERAL].present?
      return response unless number_valid_and_possible?(number,
                                                        data[Core::GENERAL])

      (Core::TYPES.keys - Core::NOT_FOR_CHECK).each do |type|
        next unless data[type].present?

        response[:valid] << type if number_valid_and_possible?(number,
                                                               data[type])
        response[:possible] << type if number_possible?(number, data[type])
      end

      if number_valid_and_possible?(number, data[Core::FIXED_LINE])
        if data[Core::FIXED_LINE] == data[Core::MOBILE]
          response[:valid] << Core::FIXED_OR_MOBILE
        else
          response[:valid] << Core::FIXED_LINE
        end
      elsif number_valid_and_possible?(number, data[Core::MOBILE])
        response[:valid] << Core::MOBILE
      end

      if number_possible?(number, data[Core::FIXED_LINE])
        if data[Core::FIXED_LINE] == data[Core::MOBILE]
          response[:possible] << Core::FIXED_OR_MOBILE
        else
          response[:possible] << Core::FIXED_LINE
        end
      elsif number_possible?(number, data[Core::MOBILE])
        response[:possible] << Core::MOBILE
      end

      response
    end
  end
end