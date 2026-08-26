# frozen_string_literal: true

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
# Validates that the original value includes an explicit international prefix.
# Both + and 00 prefixes are accepted.
#
#   class Phone < ActiveRecord::Base
#     validates :number, phone: { require_international_prefix: true }
#   end
#
# Validates that the original value uses canonical E.164 input format.
#
#   class Phone < ActiveRecord::Base
#     validates :number, phone: { format: :e164 }
#   end
#

if defined?(I18n)
  locale_files = Dir[File.expand_path('../phonelib/locale/*.yml', __dir__)]
  I18n.load_path = locale_files | I18n.load_path
end

class PhoneValidator < ActiveModel::EachValidator
  E164_PATTERN = /\A\+[1-9][0-9]{1,14}\z/
  SUPPORTED_FORMATS = [:e164, 'e164'].freeze

  # Include all core methods
  include Phonelib::Core

  def check_validity!
    return unless options.has_key?(:format)
    return if SUPPORTED_FORMATS.include?(options[:format])

    raise ArgumentError, "Unsupported phone format: #{options[:format]}"
  end

  # Validation method
  def validate_each(record, attribute, value)
    return if options[:allow_blank] && value.blank?

    phone = parse(value, specified_country(record))
    if detailed_errors?
      return validate_with_details(record, attribute, phone)
    end

    valid = phone_valid?(phone) && valid_types?(phone) && valid_country?(phone) &&
            valid_extensions?(phone) && valid_international_prefix?(phone) &&
            valid_input_format?(value)
    record.errors.add(attribute, message, **legacy_error_options) unless valid
  end

  private

  def message
    options[:message] || :invalid
  end

  def detailed_errors?
    options[:detailed_errors]
  end

  def legacy_error_options
    options.reject { |key, _value| key == :detailed_errors }
  end

  def validate_with_details(record, attribute, phone)
    result = phone.validation(
      possible: !!options[:possible],
      types: detailed_types,
      countries: detailed_countries,
      extensions: extensions_allowed?
    )
    return if result.valid?

    result.errors.each do |error|
      record.errors.add(
        attribute,
        "phone_#{error.code}".to_sym,
        **detailed_error_options(error)
      )
    end
  end

  def detailed_error_options(error)
    details = error.details.dup
    details.delete(:error)
    details.delete('error')
    details[:message] = options[:message] if options.key?(:message)
    details[:strict] = options[:strict] if options.key?(:strict)
    details
  end

  def detailed_types
    types.uniq if options[:types]
  end

  def detailed_countries
    return unless options[:countries]

    countries.uniq.select { |country| Phonelib.phone_data.key?(country) }
  end

  def phone_valid?(phone)
    phone.send(options[:possible] ? :possible? : :valid?)
  end

  def valid_types?(phone)
    return true unless options[:types]
    (phone_types(phone) & types).size > 0
  end

  def valid_country?(phone)
    return true unless options[:countries]
    (phone_countries(phone) & countries).size > 0
  end

  def valid_extensions?(phone)
    return true if extensions_allowed?
    phone.extension.empty?
  end

  def extensions_allowed?
    !options.has_key?(:extensions) || !!options[:extensions]
  end

  def valid_international_prefix?(phone)
    return true unless options[:require_international_prefix]

    phone.explicit_international_prefix?
  end

  def valid_input_format?(value)
    return true unless options[:format]

    SUPPORTED_FORMATS.include?(options[:format]) && value.is_a?(String) && value.match?(E164_PATTERN)
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
  def phone_types(phone)
    method = options[:possible] ? :possible_types : :types
    phone_types = phone.send(method)
    if (phone_types & [Phonelib::Core::FIXED_OR_MOBILE]).size > 0
      phone_types += [Phonelib::Core::FIXED_LINE, Phonelib::Core::MOBILE]
    end
    phone_types
  end

  # @private
  def phone_countries(phone)
    method = options[:possible] ? :countries : :valid_countries
    phone.send(method)
  end

  # @private
  def types
    types = options[:types].is_a?(Array) ? options[:types] : [options[:types]]
    types.map do |type|
      Phonelib::Core::TYPES_DESC_KEYS.find { |known| known.to_s == type.to_s }
    end.compact
  end

  # @private
  def countries
    countries = options[:countries].is_a?(Array) ? options[:countries] : [options[:countries]]
    countries.map { |c| c.to_s.upcase }
  end
end
