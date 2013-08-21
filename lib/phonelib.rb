module Phonelib
  # load gem classes
  autoload :Core, 'phonelib/core'
  autoload :Phone, 'phonelib/phone'

  extend Module.new {
    include Core
  }

  # Method for getting global default country setting
  def self.default_country
    @default_country
  end

  # Method for setting global default country
  def self.default_country=(country)
    @default_country = country
  end
end

if defined?(Rails)
  autoload :PhoneValidator, 'validators/phone_validator'
end
