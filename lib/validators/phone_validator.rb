class PhoneValidator < ActiveModel::EachValidator
  # Include all core methods
  include Phonelib::Core

  # Validation method
  def validate_each(record, attribute, value)
    phone = parse(value, options[:default_country])
    valid = options[:possible] ? phone.possible? : phone.valid?
    valid = true if options[:allow_blank] && phone.original.blank?

    record.errors.add(attribute, options[:message] || :invalid) unless valid
  end
end
