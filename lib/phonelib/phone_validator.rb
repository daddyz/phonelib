module Phonelib
  module Validators
    class PhoneValidator < ActiveModel::EachValidator
      include Phonelib::Core

      def validate_each(record, attribute, value)
        if options[:possible]
          ok = possible?(value)
        else
          ok = valid?(value)
        end

        # TODO: change to be from translations
        error = "is not valid"
        record.errors.add(attribute, (options[:message] || error)) unless ok
      end
    end
  end
end