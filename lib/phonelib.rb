# frozen_string_literal: true

# main Phonelib module definition
module Phonelib
  # load phonelib classes/modules
  require 'phonelib/core'
  require 'phonelib/phone_formatter'
  require 'phonelib/phone_analyzer_helper'
  require 'phonelib/phone_analyzer'
  require 'phonelib/phone_extended_data'
  require 'phonelib/validation_error'
  require 'phonelib/errors'
  require 'phonelib/validation_result'
  require 'phonelib/phone_validation'
  require 'phonelib/phone'
  require 'phonelib/locale'

  extend Core
end

autoload :PhoneValidator, 'validators/phone_validator'

Phonelib::Locale.register if defined?(I18n)

require 'phonelib/railtie' if defined?(Rails::Railtie)
