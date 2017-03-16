# Validator class for phone validations
#
# ==== Examples
#
# Validates that attribute is a valid phone number.
# If empty value passed for attribute it fails.
#
#   class Phone < ActiveRecord::Base
#     attr_accessible :number
#     validates :number, phone: true
#   end
#
# Validates that attribute is a possible phone number.
# If empty value passed for attribute it fails.
#
#   class Phone < ActiveRecord::Base
#     attr_accessible :number
#     validates :number, phone: { possible: true }
#   end
#
# Validates that attribute is a valid phone number.
# Empty value is allowed to be passed.
#
#   class Phone < ActiveRecord::Base
#     attr_accessible :number
#     validates :number, phone: { allow_blank: true }
#   end
#
# Validates that attribute is a valid phone number of specified type(s).
# It is also possible to check that attribute is a possible number of specified
# type(s). Symbol or array accepted.
#
#   class Phone < ActiveRecord::Base
#     attr_accessible :number, :mobile
#     validates :number, phone: { types: [:mobile, :fixed], allow_blank: true }
#     validates :mobile, phone: { possible: true, types: :mobile  }
#   end
#
class PhoneValidator < ActiveModel::EachValidator
  # Include all core methods
  include Phonelib::Core

  # Validation method
  def validate_each(record, attribute, value)
    return if options[:allow_blank] && value.blank?

    phone = parse(value, specified_country(record))
    valid = if simple_validation?
              phone.send(validate_method)
            else
              (phone_types(phone) & types).size > 0
            end

    record.errors.add(attribute, message, options) unless valid
  end

  private

  def message
    options[:message] || :invalid
  end

  def validate_method
    options[:possible] ? :possible? : :valid?
  end

  def specified_country(record)
    return unless options[:country_specifier]
    options[:country_specifier].call(record)
  end

  # @private
  def simple_validation?
    options[:types].nil?
  end

  # @private
  # @param phone [Phonelib::Phone] parsed phone
  def phone_types(phone)
    method = options[:possible] ? :possible_types : :types
    phone_types = phone.send(method)
    if (phone_types & [Phonelib::Core::FIXED_OR_MOBILE]).size > 0
      phone_types += [Phonelib::Core::FIXED_LINE, Phonelib::Core::MOBILE]
    end
    phone_types
  end

  # @private
  def types
    types = options[:types].is_a?(Array) ? options[:types] : [options[:types]]
    types.map(&:to_sym)
  end
end
