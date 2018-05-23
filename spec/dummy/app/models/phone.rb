class Phone < ActiveRecord::Base
  if Rails::VERSION::MAJOR != 5
    attr_accessible :number, :possible_number, :type_number, :country_number,
                    :possible_type_number, :strict_number, :country
  end

  validates :number, phone: { country_specifier: -> phone { phone.country.try(:upcase) } }
  validates :possible_number, phone: { possible: true, allow_blank: true }
  validates :type_number, phone: { types: :fixed_line, allow_blank: true }
  validates :possible_type_number, phone: { possible: true, allow_blank: true,
                                            types: [:voip, 'mobile'] }
  validates :strict_number, phone: { allow_blank: true, strict: true }
  validates :country_number, phone: { allow_blank: true, countries: [:us, :ca] }
end
