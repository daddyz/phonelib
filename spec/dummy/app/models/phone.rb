class Phone < ActiveRecord::Base
  if Rails::VERSION::MAJOR < 5
    attr_accessible :number, :possible_number, :type_number, :country_number,
                    :possible_type_number, :strict_number, :country, :type_mobile_number
  end

  validates :number, phone: { country_specifier: :specify_country }
  validates :country_specifier_proc_number, phone: { country_specifier: -> phone { phone.country.try(:upcase) }, allow_blank: true }
  validates :possible_number, phone: { possible: true, allow_blank: true }
  validates :type_number, phone: { types: :fixed_line, allow_blank: true }
  validates :possible_type_number, phone: { possible: true, allow_blank: true,
                                            types: [:voip, 'mobile'] }
  validates :strict_number, phone: { allow_blank: true, strict: true }
  validates :country_number, phone: { allow_blank: true, countries: [:us, :ca] }
  validates :type_mobile_number, phone: { possible: false, allow_blank: true, types: [:mobile] }

  private

  def specify_country
    country.try(:upcase)
  end
end
