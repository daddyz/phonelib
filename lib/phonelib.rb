module Phonelib
  autoload :Core, 'phonelib/core'
  autoload :Phone, 'phonelib/phone'
  autoload :Validators, 'phonelib/validators'

  extend Module.new {
    include Core
  }

  ActiveModel::Validations.__send__(:include, Phonelib::Validators)
end
