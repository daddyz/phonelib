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
        expect(Phonelib.possible?('97254')).to be_false
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
        expect(Phonelib.impossible?('97254')).to be_true
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

    it 'returns nil when number is nil' do
      expect(Phonelib.parse(nil).international).to be_nil
    end

    it 'returns nil when number is empty' do
      expect(Phonelib.parse('').international).to be_nil
    end
  end

  context '#national' do
    it 'returns right formatting' do
      phone = Phonelib.parse('972541234567')
      expect(phone.national).to eq('054-123-4567')
    end

    it 'returns sanitized national when number invalid but possible' do
      phone = Phonelib.parse('9721234567')
      expect(phone.valid?).to be_false
      expect(phone.possible?).to be_true
      expect(phone.national).to eq('1234567')
    end

    it 'return without leading digit for CN number' do
      phone = Phonelib.parse('18621374266', 'CN')
      expect(phone.national).to eq('186 2137 4266')
    end
  end

  context '#e164' do
    it 'returns right e164 phone' do
      phone = Phonelib.parse('972541234567')
      expect(phone.e164).to eq('+972541234567')
    end

    it 'returns sanitized when number invalid but possible' do
      phone = Phonelib.parse('9721234567')
      expect(phone.e164).to eq('+9721234567')
    end

    it 'returns nil when number is blank' do
      expect(Phonelib.parse(nil).e164).to be_nil
    end

    it 'returns nil when number is empty' do
      expect(Phonelib.parse('').e164).to be_nil
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

    it 'returns [:mobile] as all types and possible_types' do
      expect(@phone.types).to eq([:mobile])
      possible_types = [:premium_rate, :toll_free, :voip, :no_international_dialling, :mobile]
      expect(@phone.possible_types).to eq(possible_types)
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

  context 'country_code' do
    it 'returns 1 as country code' do
      phone = Phonelib.parse('17731231234')
      expect(phone.country_code).to eq("1")
    end

    it 'returns 7 as country code' do
      phone = Phonelib.parse('78005500500')
      expect(phone.country_code).to eq("7")
    end

    it 'returns nil as country code if no country' do
      phone = Phonelib.parse('7731231234')
      expect(phone.country_code).to be_nil
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

  context 'extended data' do
    it 'should have geo_name' do
      phone = Phonelib.parse('12015551234')
      expect(phone.geo_name).to eq('NewJersey')
    end

    it 'should have timezone' do
      phone = Phonelib.parse('12015551234')
      expect(phone.timezone).to eq('America/New_York')
    end

    it 'should have carrier' do
      phone = Phonelib.parse('+4915123456789')
      expect(phone.carrier).to eq('T-Mobile')
    end

    it 'should be present when invalid but possible' do
      phone = Phonelib.parse('9721234567', :il)
      expect(phone.valid?).to be_false
      expect(phone.possible?).to be_true
      expect(phone.timezone).to eq('Asia/Jerusalem')
    end

    it 'should not have ext data when impossible' do
      phone = Phonelib.parse('71')
      expect(phone.valid?).to be_false
      expect(phone.possible?).to be_false
      expect(phone.geo_name).to be_nil
      expect(phone.timezone).to be_nil
      expect(phone.carrier).to be_nil
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

  context 'issue #19' do
    it 'should parse as valid numbers with international prefix' do
      phone1 = Phonelib.parse('0049032123456789', 'GB')
      phone2 = Phonelib.parse('81049032123456789', 'RU')
      phone3 = Phonelib.parse('81049032123456789', 'GB')
      expect(phone1.valid?).to be_true
      expect(phone1.country).to eq('DE')
      expect(phone2.valid?).to be_true
      expect(phone2.country).to eq('DE')
      expect(phone3.valid?).to be_false
    end
  end

  context 'issue #20' do
    it 'should parse with special characters' do
      expect(Phonelib.parse('(202) 867-5309', 'US').valid?).to be_true
      expect(Phonelib.parse('2028675309', 'US').valid?).to be_true
    end
  end

  context 'issue #21' do
    it 'should parse without country code' do
      phone1 = Phonelib.parse '+81 90 1234 5678', 'JP'
      expect(phone1.valid_for_country?('JP')).to be_true
      phone2 = Phonelib.parse '90 1234 5678', 'JP'
      expect(phone2.valid_for_country?('JP')).to be_true
    end
  end

  context 'issue #27' do
    it 'should not raise error while parsing invalid numbers' do
      test_cases = [
        ['0000', 'PH'], ['0000', 'IN'],
        ['01114552586', 'US'], ['01148209679', 'CA'],
        ['000000000000000', 'CN'], ['0050016323', 'KR']
      ]
      test_cases.each_with_index do |test_case, i|
        number, country = test_case
        phone = Phonelib.parse number, country
        expect(phone.valid_for_country?(country)).to be_false
      end
    end
  end

  context 'issue #33' do
    it 'should be valid for mexico numbers' do
      number = Phonelib.parse('+5215545258448', 'mx')
      expect(number.valid?).to be_true
      expect(number.international).to eq('+52 1 55 4525 8448')
      expect(number.national).to eq('044 55 4525 8448')

      intl = number.international

      expect(Phonelib.valid?(intl)).to be_true
      expect(Phonelib.valid_for_country?(intl, 'mx')).to be_true
    end
  end

  context 'issue #43' do
    it 'should parse german five-digit area codes correctly' do
      number = Phonelib.parse('+492304973401', 'de')
      expect(number.valid?).to be_true
      expect(number.international).to eq('+49 2304 973401')
      expect(number.national).to eq('02304 973401')
      expect(number.geo_name).to eq('Schwerte')
    end
  end

  context 'issue #45' do
    it 'should parse possible finish number' do
      number = Phonelib.parse('030710', :fi)
      expect(number.valid?).to be_false
      expect(number.possible?).to be_true
    end
  end

  context 'issue #46' do
    it "2503019 should be possible number for us, but can't" do
      # this number can't be possible, it matches only with generalDesc
      # possible pattern, but it is not possible for any of the country types.
      # Google's library returns possible because of generalDesc match,
      # this library works in a different way, it should now the type of phone,
      # so this library can't determine number as possible
      number = Phonelib.parse('2503019', :us)
      expect(number.valid?).to be_false
      expect(number.possible?).to be_false
    end

    it '026875105 should be possible number for hk' do
      number = Phonelib.parse('026875105', :hk)
      expect(number.valid?).to be_false
      expect(number.possible?).to be_true
    end
  end

  context 'issue #49' do
    it 'should be invalid for countries if + present' do
      expect(Phonelib.valid_for_country?('+591 3 3466166', 'DE')).to be_false
      expect(Phonelib.valid_for_country?('+55 11 2606-1011', 'DE')).to be_false
      expect(Phonelib.valid_for_country?('+7 926 398-00-95', 'DE')).to be_false
      expect(Phonelib.valid_for_country?('+55 1 5551234', 'AT')).to be_false
      expect(Phonelib.valid_for_country?('+57 1 2265858', 'DE')).to be_false
    end

    it 'should be valid for countries if no + in number' do
      expect(Phonelib.valid_for_country?('591 3 3466166', 'DE')).to be_true
      expect(Phonelib.valid_for_country?('55 11 2606-1011', 'DE')).to be_true
      expect(Phonelib.valid_for_country?('7 926 398-00-95', 'DE')).to be_true
      expect(Phonelib.valid_for_country?('55 1 5551234', 'AT')).to be_true
      expect(Phonelib.valid_for_country?('57 1 2265858', 'DE')).to be_true
    end
  end

  context 'the country has a specific rule for parsing a national code' do
    let(:valid_belarus_national_number){ Phonelib.parse('80298570767', 'BY') }

    it { expect(valid_belarus_national_number).to be_valid }
  end

  context 'issue #51, outdated data' do
    it 'should return TT as country' do
      Phonelib.default_country = nil
      phone = Phonelib.parse('+18682739106')
      expect(phone.country).to eq('TT')
    end
  end

  context 'issue #54' do
    it 'should be fixed_or_mobile when phone valid for both but different patterns' do
      phone = Phonelib.parse '+15146591112'
      expect(phone.valid?).to be_true
      expect(phone.type).to eq(:fixed_or_mobile)
      expect(phone.types).to eq([:fixed_or_mobile])
    end
  end

  context 'issue #55' do
    it 'should not throw error' do
      phone = Phonelib.parse('119660086441')
      expect(phone.valid?).to be_true
    end
  end

  context 'issue #57' do
    it 'should return US as country' do
      phone = Phonelib.parse('+17295470713')
      expect(phone.valid?).to be_false
      expect(phone.possible?).to be_true
      expect(phone.country).to eq('US')
      expect(phone.valid_country).to be_nil
    end
  end

  context 'example numbers' do
    it 'are valid' do
      data_file = File.dirname(__FILE__) + '/../data/phone_data.dat'
      phone_data = Marshal.load(File.binread(data_file))
      phone_data.each do |key, data|
        country = data[:id]
        next unless country =~ /[A-Z]{2}/
        data[:types].each do |type, type_data|
          next unless (Phonelib::Core::TYPES_DESC.keys - Phonelib::Core::SHORT_CODES).include? type
          next unless type_data[:example_number]
          type_data[:example_number].split('|').each do |number|
            phone = Phonelib.parse(number, country)
            msg = "Phone #{number} in #{country} of #{type}"

            phone_assertions(phone, type, country, msg)
          end
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
