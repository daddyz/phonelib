# frozen_string_literal: true

# main Phonelib module definition
module Phonelib
  # load phonelib classes/modules
  require 'phonelib/core'
  require 'phonelib/phone_formatter'
  require 'phonelib/phone_analyzer_helper'
  require 'phonelib/phone_analyzer'
  require 'phonelib/phone_extended_data'
  require 'phonelib/phone'

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
