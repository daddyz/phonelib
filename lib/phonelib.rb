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

  extend Core
end

autoload :PhoneValidator, 'validators/phone_validator'

locale_files = Dir[File.expand_path('phonelib/locale/*.yml', __dir__)]
I18n.load_path = locale_files | I18n.load_path if defined?(I18n)

require 'phonelib/railtie' if defined?(Rails::Railtie)
