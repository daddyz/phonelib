begin
  require 'active_model'
rescue LoadError
  # ActiveModel is optional for standalone Phonelib usage.
end
require 'phonelib'

describe 'Detailed phone errors with input constraints' do
  def contact_for(options, value)
    klass = Class.new do
      include ActiveModel::Validations
      attr_accessor :phone_number
      def self.name
        'PhoneContact'
      end
      validates :phone_number, phone: options.merge(detailed_errors: true)
    end
    klass.new.tap { |record| record.phone_number = value }
  end

  let(:digits) do
    data = Phonelib.phone_data.fetch('NL')
    data[:country_code] + data[:types][:mobile][:example_number]
  end

  it 'rejects missing international prefixes with detailed errors enabled' do
    record = contact_for({ require_international_prefix: true }, digits)
    expect(record.valid?).to eq(false)
    expect(record.errors.messages[:phone_number]).to eq(['is not a valid phone number'])
  end

  it 'rejects noncanonical E164 input with detailed errors enabled' do
    record = contact_for({ format: :e164 }, '+' + digits[0, 2] + ' ' + digits[2..-1])
    expect(record.valid?).to eq(false)
    expect(record.errors.messages[:phone_number]).to eq(['is not a valid phone number'])
  end

  it 'checks the original value including the extension for E164 input' do
    record = contact_for({ format: :e164 }, '+' + digits + ';123')
    expect(record.valid?).to eq(false)
    expect(record.errors.messages[:phone_number]).to eq(['is not a valid phone number'])
  end

  it 'adds one input error when both constraints fail' do
    record = contact_for({ format: :e164, require_international_prefix: true }, digits)
    expect(record.valid?).to eq(false)
    expect(record.errors.messages[:phone_number]).to eq(['is not a valid phone number'])
  end

  it 'preserves custom messages for input errors' do
    record = contact_for({ format: :e164, message: 'use canonical E164' }, digits)
    expect(record.valid?).to eq(false)
    expect(record.errors.messages[:phone_number]).to eq(['use canonical E164'])
  end

  it 'preserves strict validation for input errors' do
    record = contact_for({ format: :e164, strict: true }, digits)
    expect { record.valid? }.to raise_error(ActiveModel::StrictValidationFailed)
  end

  it 'retains core policy errors alongside the input error' do
    record = contact_for({ format: :e164, countries: :us }, digits)
    expect(record.valid?).to eq(false)
    expect(record.errors.messages[:phone_number]).to eq(['is from a country that is not allowed', 'is not a valid phone number'])
  end

  it 'accepts canonical input with both constraints and detailed errors enabled' do
    expect(contact_for({ format: :e164, require_international_prefix: true }, '+' + digits).valid?).to eq(true)
  end
end if defined?(ActiveModel)
