class Phone < ActiveRecord::Base
  attr_accessible :number, :possible_number, :type_number,
                  :possible_type_number

  validates :number, phone: true
  validates :possible_number, phone: { possible: true, allow_blank: true }
  validates :type_number, phone: { types: :fixed_line, allow_blank: true }
  validates :possible_type_number, phone: { possible: true, allow_blank: true,
                                            types: [:voip, 'mobile'] }
end
