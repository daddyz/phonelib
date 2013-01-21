class Phone < ActiveRecord::Base
  attr_accessible :number

  validates :number, phone: true
end
