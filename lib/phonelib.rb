# main module definition
module Phonelib
  # load gem classes
  autoload :Core, 'phonelib/core'
  autoload :Phone, 'phonelib/phone'
  autoload :PhoneAnalyzer, 'phonelib/phone_analyzer'

  extend Module.new {
    include Core
  }
end

if defined?(ActiveModel)
  autoload :PhoneValidator, 'validators/phone_validator'
end
