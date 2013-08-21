module Phonelib
  # load gem classes
  autoload :Core, 'phonelib/core'
  autoload :Phone, 'phonelib/phone'

  extend Module.new {
    include Core
  }
end

if defined?(Rails)
  autoload :PhoneValidator, 'validators/phone_validator'
end
