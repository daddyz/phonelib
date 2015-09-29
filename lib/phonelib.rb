# main module definition
module Phonelib
  # load gem classes
  autoload :Core, 'phonelib/core'
  autoload :Phone, 'phonelib/phone'
  autoload :PhoneAnalyzer, 'phonelib/phone_analyzer'
  autoload :PhoneAnalyzerHelper, 'phonelib/phone_analyzer_helper'
  autoload :PhoneExtendedData, 'phonelib/phone_extended_data'

  extend Module.new {
    include Core
  }
end

autoload :PhoneValidator, 'validators/phone_validator' if defined?(ActiveModel) || defined?(Rails)
