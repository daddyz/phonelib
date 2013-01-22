class Phone < ActiveRecord::Base
  attr_accessible :number, :possible_number

  validates :number, phone: true
  validates :possible_number, phone: {possible: true, allow_blank: true}
end
