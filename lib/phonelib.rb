module Phonelib
  # load gem classes
  autoload :Core, 'phonelib/core'
  autoload :Phone, 'phonelib/phone'
  autoload :Validators, 'phonelib/validators'

  extend Module.new {
    include Core
  }

  if defined?(Rails)
    ActiveModel::Validations.__send__(:include, Phonelib::Validators)
  end
end
