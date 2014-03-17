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
# Validates that attribute is a possible phone number of specified type(s).
# Symbol or array accepted. If empty value passed for attribute it fails.
#
#   class Phone < ActiveRecord::Base
#     attr_accessible :number, :mobile
#     validates :number, phone: { possible: [:mobile, :fixed] }
#     validates :mobile, phone: { possible: :mobile }
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
    valid = possible_or_of_type(phone, options[:possible], options[:allow_blank])

    record.errors.add(attribute, options[:message] || :invalid) unless valid
  end

  private

    def possible_or_of_type(phone, possible=false, allow_blank=false)
      if allow_blank && phone.original.blank?
        true
      else
        if possible
          if possible.is_a? Symbol
            phone.types.include?(possible)
          elsif possible.is_a? Array
            possible.reduce(true) do |memo, obj|
              memo = memo && phone.types.include?(obj)
            end
          else
            phone.possible?
          end
        else
          phone.valid?
        end
      end
    end

end
