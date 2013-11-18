# main module definition
module Phonelib
  # load gem classes
  autoload :Core, 'phonelib/core'
  autoload :Phone, 'phonelib/phone'

  extend Module.new {
    include Core
  }
end

if defined?(ActiveModel)
  autoload :PhoneValidator, 'validators/phone_validator'
end
