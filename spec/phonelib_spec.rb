require 'phonelib'

describe Phonelib do

  it 'must be a Module' do
    expect(Phonelib).to be_a_kind_of(Module)
  end

  context '.parse' do
    before(:each) { @phone = Phonelib.parse '9721234567' }

    it 'returns a Phone object' do
      expect(@phone).to be_a(Phonelib::Phone)
    end

    it 'must be possible but not valid phone number' do
      expect(@phone.valid?).to be_false
      expect(@phone.possible?).to be_true
    end

    context 'with international formatting' do
      before(:each) { @phone = Phonelib.parse('+1 (972) 123-4567', 'US') }
      it 'returns exact original' do
        expect(@phone.original).to eq('+1 (972) 123-4567')
      end
    end
  end

  context '.valid?' do
    context 'with malformed phone number' do
      it 'should be false' do
        expect(Phonelib.valid?('sdffsd')).to be_false
      end
    end

    context 'with valid phone number' do
      it 'should be true' do
        expect(Phonelib.valid?('972541234567')).to be_true
      end
    end

    context 'with invalid phone number' do
      it 'should be false' do
        expect(Phonelib.valid?('97254123')).to be_false
      end
    end
  end

  context '.invalid?' do
    context 'with malformed phone number' do
      it 'should be true' do
        expect(Phonelib.invalid?('sdffsd')).to be_true
      end
    end

    context 'with valid phone number' do
      it 'should be false' do
        expect(Phonelib.invalid?('972541234567')).to be_false
      end
    end

    context 'with invalid phone number' do
      it 'should be true' do
        expect(Phonelib.invalid?('97254123')).to be_true
      end
    end
  end

  context '.possible?' do
    context 'with valid phone number' do
      it 'should be true' do
        expect(Phonelib.possible?('972541234567')).to be_true
      end
    end

    context 'with invalid phone number' do
      it 'should be false' do
        expect(Phonelib.possible?('97254123')).to be_false
      end
    end
  end

  context '.impossible?' do
    context 'with valid phone number' do
      it 'should be false' do
        expect(Phonelib.impossible?('972541234567')).to be_false
      end
    end

    context 'with invalid phone number' do
      it 'should be true' do
        expect(Phonelib.impossible?('97254123')).to be_true
      end
    end
  end

  context 'valid_for_country?' do
    context 'with correct data' do
      ['IL', 'il', :il].each do |country|
        context "with #{country} as country" do
          it 'should be true' do
            expect(Phonelib.valid_for_country?('972541234567', country)).to\
                be_true
          end

          context 'and national number' do
            it 'should be true' do
              expect(Phonelib.valid_for_country?('0541234567', country)).to\
                  be_true
            end
          end

          context 'and without prefix' do
            it 'should be true' do
              expect(Phonelib.valid_for_country?('541234567', country)).to\
                  be_true
            end
          end
        end
      end
    end

    ['US', 'us', :us].each do |country|
      context "with #{country} as country" do
        context 'with incorrect data' do
          it 'should be false' do
            expect(Phonelib.valid_for_country?('972541234567', country)).to\
                be_false
          end

          context 'and without prefix' do
            it 'should be false' do
              expect(Phonelib.valid_for_country?('541234567', country)).to\
                  be_false
            end
          end
        end
      end
    end
  end

  context '.invalid_for_country?' do
    context 'with correct data' do
      ['IL', 'il', :il].each do |country|
        context "with #{country} as country" do
          it 'should be false' do
            expect(Phonelib.invalid_for_country?('972541234567', country)).to\
                be_false
          end
        end
      end
    end

    context 'with incorrect data' do
      ['US', 'us', :us].each do |country|
        context "with #{country} as country" do
          it 'should be true' do
            expect(Phonelib.invalid_for_country?('972541234567', country)).to\
                be_true
          end
        end
      end
    end
  end

  context '#international' do
    it 'returns right formatting' do
      phone = Phonelib.parse('972541234567')
      expect(phone.international).to eq('+972 54-123-4567')
    end

    it 'returns sanitized when number invalid but possible' do
      phone = Phonelib.parse('9721234567')
      expect(phone.international).to eq('+9721234567')
    end
  end

  context '#national' do
    it 'returns right formatting' do
      phone = Phonelib.parse('972541234567')
      expect(phone.national).to eq('054-123-4567')
    end

    it 'returns sanitized national when number invalid but possible' do
      phone = Phonelib.parse('9721234567')
      expect(phone.national).to eq('1234567')
    end

    it 'return without leading digit for CN number' do
      phone = Phonelib.parse('18621374266', 'CN')
      expect(phone.national).to eq('186 2137 4266')
    end
  end

  context 'types' do
    before(:all) { @phone = Phonelib.parse('972541234567') }
    it 'returns :mobile type' do
      expect(@phone.type).to eq(:mobile)
    end

    it 'returns Mobile human type' do
      expect(@phone.human_type).to eq('Mobile')
    end

    it 'returns [:mobile] as all types' do
      expect(@phone.types).to eq([:mobile])
    end

    it 'returns [Mobile] as all human types' do
      expect(@phone.human_types).to eq(%w(Mobile))
    end
  end

  context 'country' do
    it 'returns IL as country' do
      phone = Phonelib.parse('972541234567')
      expect(phone.country).to eq('IL')
    end

    it 'returns RU as country' do
      phone = Phonelib.parse('78005500500')
      expect(phone.country).to eq('RU')
    end
  end

  context 'default_country' do
    it 'should be invalid with no default country set' do
      phone = Phonelib.parse('541234567')
      expect(phone.valid?).to be_false
    end

    it 'should be valid with default country set' do
      Phonelib.default_country = :IL
      phone = Phonelib.parse('541234567')
      expect(phone.valid?).to be_true
    end

    it 'should be valid with wrong default country set' do
      Phonelib.default_country = :UA
      phone = Phonelib.parse('972541234567')
      expect(phone.valid?).to be_true
    end

    it 'should not fail when no phone passed and default country set' do
      Phonelib.default_country = :UA
      phone = Phonelib.parse(nil)
      expect(phone.invalid?).to be_true
    end

    it 'should be valid when number invalid for default country' do
      Phonelib.default_country = :CN
      phone = Phonelib.parse('+41 44 668 18 00')
      expect(phone.valid?).to be_true
    end
  end

  context 'issue #16' do
    it 'should parse as LT country' do
      phone = Phonelib.parse('00370 611 11 111')
      expect(phone.country).to eq('LT')
    end

    it 'shows correct international' do
      phone = Phonelib.parse('370 611 11 111')
      expect(phone.international).to eq('+370 611 11111')
    end
  end

  context 'issue #18' do
    it 'not raise exceptions' do
      expect(Phonelib.parse('54932', 'DE').national).to be_kind_of(String)
      expect(Phonelib.parse('33251304029', 'LU').national).to be_kind_of(String)
      expect(Phonelib.parse('61130374', 'AU').national).to be_kind_of(String)
    end
  end

  context 'example numbers' do
    it 'be valid' do
      data_file = File.dirname(__FILE__) + '/../data/phone_data.dat'
      phone_data ||= Marshal.load(File.read(data_file))
      phone_data.each do |data|
        country = data[:id]
        next unless country =~ /[A-Z]{2}/
        data[:types].each do |type, type_data|
          next unless Phonelib::Core::TYPES_DESC.keys.include? type
          next unless type_data[:example_number]
          number = "#{type_data[:example_number]}"
          phone = Phonelib.parse(number, country)
          msg = "Phone #{number} in #{country} of #{type}"

          phone_assertions(phone, type, country, msg)
        end
      end
    end

    def phone_assertions(phone, type, country, msg)
      expect(phone.valid?).to be_true, "#{msg} not valid"
      expect(phone.invalid?).to be_false, "#{msg} not valid"
      expect(phone.possible?).to be_true, "#{msg} not possible"
      expect(phone.impossible?).to be_false, "#{msg} not possible"
      expect(phone.valid_for_country?(country)).to be_true,
             "#{msg} not valid for country"
      expect(phone.invalid_for_country?(country)).to be_false,
             "#{msg} not valid for country"

      expect(phone.country).to eq(country), "#{msg} wrong country "
      if phone.type == Phonelib::Core::FIXED_OR_MOBILE
        expect([Phonelib::Core::FIXED_LINE, Phonelib::Core::MOBILE]).to\
            include(type)
            "#{msg} wrong type #{phone.types}"
      else
        expect(phone.types).to include(type),
            "#{msg} wrong type #{phone.types}"
      end
    end
  end
end