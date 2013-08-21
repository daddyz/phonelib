module Phonelib
  # load gem classes
  autoload :Core, 'phonelib/core'
  autoload :Phone, 'phonelib/phone'

  extend Module.new {
    include Core
  }

  def self.default_country
    @default_country
  end

  def self.default_country=(country)
    @default_country = country
  end
end

if defined?(Rails)
  autoload :PhoneValidator, 'validators/phone_validator'
end
