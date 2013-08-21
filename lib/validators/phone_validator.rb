class PhoneValidator < ActiveModel::EachValidator
  # Include all core methods
  include Phonelib::Core

  # Validation method
  def validate_each(record, attribute, value)
    phone = parse(value)
    valid = options[:possible] ? phone.possible? : phone.valid?
    valid = true if options[:allow_blank] && phone.original.blank?

    # TODO: change to be from translations
    error = "is not valid"
    record.errors.add(attribute, (options[:message] || error)) unless valid
  end
end
