require File.expand_path('../../spec_helper.rb',  __FILE__)

describe Phone do
  it 'saves with valid phone' do
    phone = Phone.new(number: '972542234567')

    expect(phone.save).to be true
    expect(phone.errors.empty?).to be true
  end

  it "can't save with invalid phone" do
    phone = Phone.new(number: 'wrong')

    expect(phone.save).to be false
    expect(phone.errors.any?).to be true
  end

  it "is invalid when phone is invalid and country is specified" do
    phone = Phone.new(number: '1305558858', country: 'us')

    expect(phone.valid?).to be false
    expect(phone.errors.any?).to be true
  end

  it "is valid when phone is valid and country is specified" do
    phone = Phone.new(number: '3175082248', country: 'us')

    expect(phone.valid?).to be true
    expect(phone.errors.any?).to be false
  end

  it 'passes when valid' do
    phone = phones(:valid_and_possible)
    expect(phone.save).to be true
    expect(phone.errors.empty?).to be true
  end

  it 'fails with wrong' do
    phone = phones(:wrong)
    expect(phone.save).to be false
    expect(phone.errors.any?).to be true
  end

  it 'passes with allow blank' do
    phone = phones(:only_valid)
    expect(phone.save).to be true
    expect(phone.errors.empty?).to be true
  end

  it 'fails without allow blank' do
    phone = phones(:only_possible)
    expect(phone.save).to be false
    expect(phone.errors.any?).to be true
  end

  it 'fails when wrong possible and not blank' do
    phone = phones(:valid_with_bad_possible)
    expect(phone.save).to be false
    expect(phone.errors.any?).to be true
  end

  it 'should pass with valid type' do
    phone = phones(:valid_type)
    expect(phone.save).to be true
    expect(phone.errors.empty?).to be true
  end

  it 'should fail with invalid type' do
    phone = phones(:invalid_type)
    expect(phone.save).to be false
    expect(phone.errors.any?).to be true
  end

  it 'should pass with possible type' do
    phone = phones(:possible_type)
    expect(phone.save).to be true
    expect(phone.errors.empty?).to be true
  end

  it 'should fail with impossible type' do
    phone = phones(:impossible_type)
    expect(phone.save).to be false
    expect(phone.errors.any?).to be true
  end

  it 'should raise ActiveModel::StrictValidationFailed on strict fields' do
    if Rails::VERSION::STRING >= '3.2'
      phone = phones(:invalid_strict)
      expect{phone.valid?}.to raise_error(ActiveModel::StrictValidationFailed)
    else
      # this test is suitable for rails >= 3.2 only
    end
  end

  it 'should save with valid country phone' do
    phone = phones(:valid_countries)
    expect(phone.save).to be true
    expect(phone.errors.any?).to be false
  end

  it 'should fail with impossible type' do
    phone = phones(:invalid_countries)
    expect(phone.save).to be false
    expect(phone.errors.any?).to be true
  end

  it 'should pass with mobile valid type' do
    Phonelib.default_country = 'IN'
    phone = phones(:mobile_or_fixed_valid_type)
    expect(phone.save).to be true
    Phonelib.default_country = nil
  end

  it 'should fail with fixed valid number but mobile type defined' do
    Phonelib.default_country = 'IN'
    phone = phones(:fixed_valid_type)
    expect(phone.save).to be false
    expect(phone.errors.any?).to be true
    Phonelib.default_country = nil
  end

end

describe 'detailed phone validation' do
  def validation_model(options)
    Class.new do
      include ActiveModel::Validations

      attr_accessor :number, :country

      def self.model_name
        ActiveModel::Name.new(self, nil, 'DetailedPhoneValidationModel')
      end
    end.tap do |model|
      model.validates :number, phone: options
    end
  end

  def validate_number(options, number, country = nil)
    model = validation_model(options).new
    model.number = number
    model.country = country
    model.valid?
    model
  end

  it 'keeps the legacy invalid error when detailed errors are not enabled' do
    model = validate_number({}, 'wrong')

    expect(model).not_to be_valid
    if model.errors.respond_to?(:details)
      expect(model.errors.details[:number]).to eq([{ error: :invalid }])
    else
      expect(model.errors[:number]).to eq(['is invalid'])
    end
  end

  it 'adds the core error code and details when detailed errors are enabled' do
    skip 'requires ActiveModel::Errors#details' unless ActiveModel::Errors.method_defined?(:details)
    model = validate_number({ detailed_errors: true }, 'wrong')

    expect(model).not_to be_valid
    expect(model.errors.details[:number]).to eq([{ error: :phone_not_a_number }])
  end

  it 'allows a custom message without changing the detailed error type' do
    model = validate_number(
      { detailed_errors: true, message: 'is not a phone number' },
      'wrong'
    )

    expect(model).not_to be_valid
    if model.errors.respond_to?(:details)
      expect(model.errors.details[:number]).to eq([
        { error: :phone_not_a_number }
      ])
    end
    expect(model.errors.messages[:number]).to eq(['is not a phone number'])
  end

  it 'lets the application override the bundled detailed error translation' do
    model = validate_number(
      { detailed_errors: true, types: :mobile },
      '+442079460018'
    )

    expect(model).not_to be_valid
    expect(model.errors.messages[:number]).to eq([
      'application phone type override'
    ])
  end

  it 'keeps unknown type options as a validation failure' do
    model = validate_number(
      { detailed_errors: true, types: :unrecognized },
      '+442079460018'
    )

    expect(model).not_to be_valid
    expect(model.errors.messages[:number]).to eq([
      'application phone type override'
    ])
    if model.errors.respond_to?(:details)
      expect(model.errors.details[:number].first[:error]).to eq(
        :phone_type_not_allowed
      )
    end
  end

  it 'keeps non-string country options as a validation failure' do
    model = validate_number(
      { detailed_errors: true, countries: 1 },
      '+442079460018'
    )

    expect(model).not_to be_valid
    expect(model.errors.messages[:number]).to eq([
      'is from a country that is not allowed'
    ])
    if model.errors.respond_to?(:details)
      expect(model.errors.details[:number].first[:error]).to eq(
        :phone_country_not_allowed
      )
    end
  end

  it 'uses precise wording for an invalid country calling code' do
    model = validate_number(
      { detailed_errors: true },
      '+210 3456 56789'
    )

    expect(model).not_to be_valid
    expect(model.errors.messages[:number]).to eq([
      'has an invalid country calling code'
    ])
  end

  it 'honors allow_blank before evaluating detailed errors' do
    model = validate_number({ detailed_errors: true, allow_blank: true }, '')

    expect(model).to be_valid
    expect(model.errors).to be_empty
  end

  it 'uses country_specifier when evaluating detailed errors' do
    model = validate_number(
      {
        detailed_errors: true,
        country_specifier: ->(record) { record.country }
      },
      '2079460018',
      'GB'
    )

    expect(model).to be_valid
    expect(model.errors).to be_empty
  end

  it 'preserves legacy possible validation for local-only numbers' do
    skip 'requires ActiveModel::Errors#details' unless ActiveModel::Errors.method_defined?(:details)
    model = validate_number(
      { detailed_errors: true, possible: true },
      '+49 12'
    )

    expect(model).not_to be_valid
    expect(model.errors.details[:number]).to eq([
      { error: :phone_not_possible, possibility: :possible_local_only }
    ])
  end

  it 'reports the intrinsic legacy failure before local-only policy failures' do
    skip 'requires ActiveModel::Errors#details' unless ActiveModel::Errors.method_defined?(:details)
    model = validate_number(
      { detailed_errors: true, possible: true, types: :mobile },
      '+49 12'
    )

    expect(model).not_to be_valid
    expect(model.errors.details[:number]).to eq([
      { error: :phone_not_possible, possibility: :possible_local_only }
    ])
  end

  it 'does not change acceptance solely because a parser diagnostic is available' do
    number = '+1 6502530000'
    input = (' ' * (251 - number.length)) + number

    model = validate_number({ detailed_errors: true }, input)

    expect(model).to be_valid
    expect(model.errors).to be_empty
  end

  it 'rejects an invalid country specifier in possible mode' do
    skip 'requires ActiveModel::Errors#details' unless ActiveModel::Errors.method_defined?(:details)
    model = validate_number(
      {
        detailed_errors: true,
        possible: true,
        country_specifier: ->(record) { record.country }
      },
      '+1 6502530000',
      'ZZ'
    )

    expect(model).not_to be_valid
    expect(model.errors.details[:number]).to eq([
      { error: :phone_not_possible, possibility: :possible }
    ])
  end

  it 'adds each independent policy error in a deterministic order' do
    skip 'requires ActiveModel::Errors#details' unless ActiveModel::Errors.method_defined?(:details)
    model = validate_number(
      {
        detailed_errors: true,
        types: :mobile,
        countries: :us,
        extensions: false
      },
      '+442079460018;42'
    )

    expect(model).not_to be_valid
    expect(model.errors.details[:number].map { |error| error[:error] }).to eq([
      :phone_type_not_allowed,
      :phone_country_not_allowed,
      :phone_extension_not_allowed
    ])
    expect(model.errors.details[:number].first).to include(
      allowed_types: [:mobile],
      matched_types: [:fixed_line]
    )
    expect(model.errors.details[:number][1]).to include(
      allowed_countries: ['US']
    )
    expect(model.errors.details[:number][2]).to include(
      extension_present: true
    )
  end

  it 'honors strict with detailed errors' do
    model = validation_model(detailed_errors: true, strict: true).new
    model.number = 'wrong'

    expect { model.valid? }.to raise_error(ActiveModel::StrictValidationFailed)
  end
end
