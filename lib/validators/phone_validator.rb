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
# validates that phone is valid and it is from specified country or countries
#
#   class Phone < ActiveRecord::Base
#     attr_accessible :number
#     validates :number, phone: { countries: [:us, :ca] }
#   end
#
# Validates that attribute does not include an extension.
# The default setting is to allow extensions
#
#   class Phone < ActiveRecord::Base
#     attr_accessible :number
#     validates :number, phone: { extensions: false }
#   end
#
class PhoneValidator < ActiveModel::EachValidator
  # Include all core methods
  include Phonelib::Core

  # Validation method
  def validate_each(record, attribute, value)
    return if options[:allow_blank] && value.blank?

    @phone = parse(value, specified_country(record))
    valid = phone_valid? && valid_types? && valid_country? && valid_extensions?

    record.errors.add(attribute, message, options) unless valid
  end

  private

  def message
    options[:message] || :invalid
  end

  def phone_valid?
    @phone.send(options[:possible] ? :possible? : :valid?)
  end

  def valid_types?
    return true unless options[:types]
    (phone_types & types).size > 0
  end

  def valid_country?
    return true unless options[:countries]
    (phone_countries & countries).size > 0
  end

  def valid_extensions?
    return true if !options.has_key?(:extensions) || options[:extensions]
    @phone.extension.empty?
  end

  def specified_country(record)
    return unless options[:country_specifier]

    if options[:country_specifier].is_a?(Symbol)
      record.send(options[:country_specifier])
    else
      options[:country_specifier].call(record)
    end
  end

  # @private
  def phone_types
    method = options[:possible] ? :possible_types : :types
    phone_types = @phone.send(method)
    if (phone_types & [Phonelib::Core::FIXED_OR_MOBILE]).size > 0
      phone_types += [Phonelib::Core::FIXED_LINE, Phonelib::Core::MOBILE]
    end
    phone_types
  end

  # @private
  def phone_countries
    method = options[:possible] ? :countries : :valid_countries
    @phone.send(method)
  end

  # @private
  def types
    types = options[:types].is_a?(Array) ? options[:types] : [options[:types]]
    types.map(&:to_sym)
  end

  # @private
  def countries
    countries = options[:countries].is_a?(Array) ? options[:countries] : [options[:countries]]
    countries.map { |c| c.to_s.upcase }
  end
end
