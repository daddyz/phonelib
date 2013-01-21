module Phonelib
  autoload :Core, 'phonelib/phonelib_core'
  autoload :Phone, 'phonelib/phone'
  autoload :Validators, 'phonelib/phone_validator'

  extend Module.new {
    include Core
  }

  ActiveModel::Validations.__send__(:include, Phonelib::Validators)
end
