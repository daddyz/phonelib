module Phonelib
  autoload :Core, 'phonelib/phonelib_core'
  autoload :Phone, 'phonelib/phone'

  extend Module.new {
    include Core
  }
end
