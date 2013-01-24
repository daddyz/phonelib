module Phonelib
  # Module includes all ActiveModel validators classes
  module Validators
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
  end
end