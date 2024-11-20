# frozen_string_literal: true

# main Phonelib module definition
module Phonelib
  # load phonelib classes/modules
  autoload :Core, 'phonelib/core'
  autoload :Phone, 'phonelib/phone'
  autoload :PhoneFormatter, 'phonelib/phone_formatter'
  autoload :PhoneAnalyzer, 'phonelib/phone_analyzer'
  autoload :PhoneAnalyzerHelper, 'phonelib/phone_analyzer_helper'
  autoload :PhoneExtendedData, 'phonelib/phone_extended_data'

  extend Core
end

if defined?(ActiveModel) || defined?(Rails)
  autoload :PhoneValidator, 'validators/phone_validator'

  if defined?(Rails)
    class Phonelib::Railtie < Rails::Railtie
      initializer 'phonelib' do |app|
        app.config.eager_load_namespaces << Phonelib
      end
    end
  end
end
