# frozen_string_literal: true

begin
  require 'active_model'
rescue LoadError
  # PhoneValidator is only available when ActiveModel is installed.
end

require 'phonelib'

if defined?(ActiveModel)
  describe PhoneValidator do
    before(:all) do
      Phonelib.override_phone_data = 'spec/dummy/lib/override_phone_data.dat'
    end

    let(:model_class) do
      Class.new do
        include ActiveModel::Validations

        attr_accessor :phone_number

        validates :phone_number, phone: { require_international_prefix: true }
      end
    end

    let(:record) { model_class.new }

    context 'without an input constraint' do
      let(:model_class) do
        Class.new do
          include ActiveModel::Validations

          attr_accessor :phone_number

          validates :phone_number, phone: true
        end
      end

      it 'keeps accepting a valid phone number without an international prefix' do
        record.phone_number = '41442511234'

        expect(record).to be_valid
      end
    end

    context 'when an international prefix is required' do
      it 'accepts a valid phone number with an international prefix' do
        record.phone_number = '+41442511234'

        expect(record).to be_valid
      end

      it 'accepts double zero as an international prefix' do
        record.phone_number = '0041442511234'

        expect(record).to be_valid
      end

      it 'accepts an international prefix behind leading formatting characters' do
        record.phone_number = '(+41) 44 251 12 34'

        expect(record).to be_valid
      end

      it 'rejects a valid phone number without an international prefix' do
        record.phone_number = '41442511234'

        expect(record).not_to be_valid
      end

      context 'with vanity conversion enabled' do
        before do
          Phonelib.vanity_conversion = true
        end

        after do
          Phonelib.vanity_conversion = false
        end

        it 'rejects a plus sign following a vanity digit' do
          record.phone_number = 'G+376712345'

          expect(record).not_to be_valid
        end

        it 'rejects double zero following a vanity digit' do
          record.phone_number = 'T0024762889'

          expect(record).not_to be_valid
        end
      end
    end

    context 'when E.164 format is required' do
      let(:input_format) { :e164 }

      let(:model_class) do
        format = input_format

        Class.new do
          include ActiveModel::Validations

          attr_accessor :phone_number

          validates :phone_number, phone: { format: format }
        end
      end

      it 'accepts a valid phone number in canonical E.164 format' do
        record.phone_number = '+41442511234'

        expect(record).to be_valid
      end

      it 'accepts a valid phone number with the E.164 maximum of 15 digits' do
        record.phone_number = '+498001234567890'

        expect(record).to be_valid
      end

      it 'rejects an internationally formatted phone number that is not canonical E.164' do
        record.phone_number = '+41 44 251 12 34'

        expect(record).not_to be_valid
      end

      it 'rejects a phone number with a double-zero prefix' do
        record.phone_number = '0041442511234'

        expect(record).not_to be_valid
      end

      {
        'a single digit' => '+1',
        'an otherwise canonical but invalid two-digit phone number' => '+12',
        'more than 15 digits' => '+4980012345678901',
        'a leading zero' => '+041442511234',
        'an extension' => '+41442511234;123',
        'a non-string input' => 41442511234
      }.each do |description, value|
        it "rejects #{description}" do
          record.phone_number = value

          expect(record).not_to be_valid
        end
      end

      context 'when configured with a string format name' do
        let(:input_format) { 'e164' }

        it 'accepts a valid canonical value' do
          record.phone_number = '+41442511234'

          expect(record).to be_valid
        end
      end
    end

    it 'rejects unsupported input formats when the validator is configured' do
      expect {
        Class.new do
          include ActiveModel::Validations

          attr_accessor :phone_number

          validates :phone_number, phone: { format: :national }
        end
      }.to raise_error(ArgumentError, 'Unsupported phone format: national')
    end
  end
end
