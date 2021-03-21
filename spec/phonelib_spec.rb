require 'phonelib'

# deprecated code climate
#require 'codeclimate-test-reporter'
#CodeClimate::TestReporter.start
require 'simplecov'
SimpleCov.start

describe Phonelib do
  before(:all) do
    Phonelib.override_phone_data = "spec/dummy/lib/override_phone_data.dat"
  end

  before(:each) do
    Phonelib.default_country = nil
    Phonelib.extension_separator = ';'
    Phonelib.extension_separate_symbols = '#;'
    Phonelib.parse_special = false
    Phonelib.strict_check = false
    Phonelib.vanity_conversion = false
  end

  it 'must be a Module' do
    expect(Phonelib).to be_a_kind_of(Module)
  end

  context '.parse' do
    before(:each) { @phone = Phonelib.parse '9721234567' }

    it 'returns a Phone object' do
      expect(@phone).to be_a(Phonelib::Phone)
    end

    it 'must be possible but not valid phone number' do
      expect(@phone.valid?).to be false
      expect(@phone.possible?).to be true
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
        expect(Phonelib.valid?('sdffsd')).to be false
      end
    end

    context 'with valid phone number' do
      it 'should be true' do
        expect(Phonelib.valid?('972542234567')).to be true
      end
    end

    context 'with invalid phone number' do
      it 'should be false' do
        expect(Phonelib.valid?('97254123')).to be false
      end
    end
  end

  context '.invalid?' do
    context 'with malformed phone number' do
      it 'should be true' do
        expect(Phonelib.invalid?('sdffsd')).to be true
      end
    end

    context 'with valid phone number' do
      it 'should be false' do
        expect(Phonelib.invalid?('972542234567')).to be false
      end
    end

    context 'with invalid phone number' do
      it 'should be true' do
        expect(Phonelib.invalid?('97254123')).to be true
      end
    end
  end

  context '.possible?' do
    context 'with valid phone number' do
      it 'should be true' do
        expect(Phonelib.possible?('972542234567')).to be true
      end
    end

    context 'with invalid phone number' do
      it 'should be false' do
        expect(Phonelib.possible?('97254')).to be false
      end
    end
  end

  context '.impossible?' do
    context 'with valid phone number' do
      it 'should be false' do
        expect(Phonelib.impossible?('972542234567')).to be false
      end
    end

    context 'with invalid phone number' do
      it 'should be true' do
        expect(Phonelib.impossible?('97254')).to be true
      end
    end
  end

  context 'valid_for_country?' do
    context 'with correct data' do
      ['IL', 'il', :il].each do |country|
        context "with #{country} as country" do
          it 'should be true' do
            expect(Phonelib.valid_for_country?('972542234567', country)).to\
                be true
          end

          context 'and national number' do
            it 'should be true' do
              expect(Phonelib.valid_for_country?('0542234567', country)).to\
                  be true
            end
          end

          context 'and without prefix' do
            it 'should be true' do
              expect(Phonelib.valid_for_country?('542234567', country)).to\
                  be true
            end
          end
        end
      end

      context 'with entry in overidden data file' do
        ['UG', 'ug', :ug].each do |country|
          context "with #{country} as country" do
            context 'with correct data' do
              it 'should be true' do
                # the number provided would be invalid if it weren't for the override file
                expect(Phonelib.valid_for_country?('812345678', country)).to\
                    be true
              end
            end
          end
        end
      end
    end

    ['US', 'us', :us].each do |country|
      context "with #{country} as country" do
        context 'with incorrect data' do
          it 'should be false' do
            expect(Phonelib.valid_for_country?('972542234567', country)).to\
                be false
          end

          context 'and without prefix' do
            it 'should be false' do
              expect(Phonelib.valid_for_country?('542234567', country)).to\
                  be false
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
            expect(Phonelib.invalid_for_country?('972542234567', country)).to\
                be false
          end
        end
      end
    end

    context 'with incorrect data' do
      ['US', 'us', :us].each do |country|
        context "with #{country} as country" do
          it 'should be true' do
            expect(Phonelib.invalid_for_country?('972542234567', country)).to\
                be true
          end
        end
      end
    end
  end

  context '#international' do
    it 'returns right formatting' do
      phone = Phonelib.parse('972542234567')
      expect(phone.international).to eq('+972 54-223-4567')
    end

    it 'returns unformatted when false passed' do
      phone = Phonelib.parse('972542234567')
      expect(phone.international(false)).to eq('+972542234567')
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
      phone = Phonelib.parse('972542234567')
      expect(phone.national).to eq('054-223-4567')
    end

    it 'returns unformatted when false passed' do
      phone = Phonelib.parse('972542234567')
      expect(phone.national(false)).to eq('0542234567')
    end

    it 'returns sanitized national when number invalid but possible' do
      phone = Phonelib.parse('9721234567')
      expect(phone.valid?).to be false
      expect(phone.possible?).to be true
      expect(phone.national).to eq('1234567')
    end

    it 'return without leading digit for CN number' do
      phone = Phonelib.parse('18621374266', 'CN')
      expect(phone.national).to eq('186 2137 4266')
    end
  end

  context '#e164' do
    it 'returns right e164 phone' do
      phone = Phonelib.parse('972542234567')
      expect(phone.e164).to eq('+972542234567')
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
    before(:all) { @phone = Phonelib.parse('972542234567') }
    it 'returns :mobile type' do
      expect(@phone.type).to eq(:mobile)
    end

    it 'returns Mobile human type' do
      expect(@phone.human_type).to eq('Mobile')
    end

    it 'returns [:mobile] as all types and possible_types' do
      expect(@phone.types).to eq([:mobile])
      possible_types = [:voip, :mobile]
      expect(@phone.possible_types).to eq(possible_types)
    end

    it 'returns [Mobile] as all human types' do
      expect(@phone.human_types).to eq(%w(Mobile))
    end
  end

  context 'country' do
    it 'returns IL as country' do
      phone = Phonelib.parse('972542234567')
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
      phone = Phonelib.parse('542234567')
      expect(phone.valid?).to be false
    end

    it 'should be valid with default country set' do
      Phonelib.default_country = :IL
      phone = Phonelib.parse('542234567')
      expect(phone.valid?).to be true
    end

    it 'should be valid with wrong default country set' do
      Phonelib.default_country = :UA
      phone = Phonelib.parse('972542234567')
      expect(phone.valid?).to be true
    end

    it 'should not fail when no phone passed and default country set' do
      Phonelib.default_country = :UA
      phone = Phonelib.parse(nil)
      expect(phone.invalid?).to be true
    end

    it 'should be valid when number invalid for default country' do
      Phonelib.default_country = :CN
      phone = Phonelib.parse('+41 44 668 18 00')
      expect(phone.valid?).to be true
      Phonelib.default_country = nil
    end
  end

  context 'extended data' do
    it 'should have geo_name' do
      phone = Phonelib.parse('12015551234')
      expect(phone.geo_name).to eq('New Jersey')
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
      expect(phone.valid?).to be false
      expect(phone.possible?).to be true
      expect(phone.timezone).to eq('Asia/Jerusalem')
    end

    it 'should not have ext data when impossible' do
      phone = Phonelib.parse('71')
      expect(phone.valid?).to be false
      expect(phone.possible?).to be false
      expect(phone.geo_name).to be_nil
      expect(phone.timezone).to be_nil
      expect(phone.carrier).to be_nil
    end

    it 'should be nil when not exist geo name' do
      phone = Phonelib.parse('0145-61-1234', 'JP')
      expect(phone.valid?).to be true
      expect(phone.geo_name).to be_nil
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
      expect(phone1.valid?).to be true
      expect(phone1.country).to eq('DE')
      expect(phone2.valid?).to be true
      expect(phone2.country).to eq('DE')
      expect(phone3.valid?).to be false
    end
  end

  context 'issue #20' do
    it 'should parse with special characters' do
      expect(Phonelib.parse('(202) 867-5309', 'US').valid?).to be true
      expect(Phonelib.parse('2028675309', 'US').valid?).to be true
    end
  end

  context 'issue #21' do
    it 'should parse without country code' do
      phone1 = Phonelib.parse '+81 90 1234 5678', 'JP'
      expect(phone1.valid_for_country?('JP')).to be true
      phone2 = Phonelib.parse '90 1234 5678', 'JP'
      expect(phone2.valid_for_country?('JP')).to be true
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
        expect(phone.valid_for_country?(country)).to be false
      end
    end
  end

  context 'issue #33' do
    it 'should be valid for mexico numbers' do
      number = Phonelib.parse('+5215545258448', 'mx')
      expect(number.valid?).to be true
      expect(number.international).to eq('+52 55 4525 8448')
      expect(number.national).to eq('55 4525 8448')

      intl = number.international

      expect(Phonelib.valid?(intl)).to be true
      expect(Phonelib.valid_for_country?(intl, 'mx')).to be true
    end
  end

  context 'issue #43' do
    it 'should parse german five-digit area codes correctly' do
      number = Phonelib.parse('+492304973401', 'de')
      expect(number.valid?).to be true
      expect(number.international).to eq('+49 2304 973401')
      expect(number.national).to eq('02304 973401')
      expect(number.geo_name).to eq('Schwerte')
    end
  end

  context 'issue #45' do
    it 'should parse possible finish number' do
      number = Phonelib.parse('030710', :fi)
      expect(number.valid?).to be false
      expect(number.possible?).to be true
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
      expect(number.valid?).to be false
      expect(number.possible?).to be false
    end

    it '026875105 should be possible number for hk' do
      number = Phonelib.parse('026875105', :hk)
      expect(number.valid?).to be false
      expect(number.possible?).to be true
    end
  end

  context 'issue #49' do
    it 'should be invalid for countries if + present' do
      expect(Phonelib.valid_for_country?('+591 3 3466166', 'DE')).to be false
      expect(Phonelib.valid_for_country?('+55 11 2606-1011', 'DE')).to be false
      expect(Phonelib.valid_for_country?('+7 926 398-00-95', 'DE')).to be false
      expect(Phonelib.valid_for_country?('+55 1 5551234', 'AT')).to be false
      expect(Phonelib.valid_for_country?('+57 1 2265858', 'DE')).to be false
    end

    it 'should be valid for countries if no + in number' do
      expect(Phonelib.valid_for_country?('591 3 3466166', 'DE')).to be true
      expect(Phonelib.valid_for_country?('55 11 2606-1011', 'DE')).to be true
      expect(Phonelib.valid_for_country?('55 1 5551234', 'AT')).to be true
      expect(Phonelib.valid_for_country?('57 1 2265858', 'DE')).to be true
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
      expect(phone.valid?).to be true
      expect(phone.type).to eq(:fixed_or_mobile)
      expect(phone.types).to eq([:fixed_or_mobile])
    end
  end

  context 'issue #55' do
    it 'should not throw error' do
      phone = Phonelib.parse('119660086441')
      expect(phone.possible?).to be true
    end
  end

  context 'issue #57' do
    it 'should return US as country' do
      phone = Phonelib.parse('+17295470713')
      expect(phone.valid?).to be false
      expect(phone.possible?).to be true
      expect(phone.country).to eq('US')
      expect(phone.valid_country).to be_nil
    end
  end

  context 'area_code method' do
    it 'should return area code' do
      expect(Phonelib.parse('+61 3 9876 0010').area_code).to eq('3')
      expect(Phonelib.parse('+44 (0) 20-7031-3000').area_code).to eq('20')
      expect(Phonelib.parse('+852 2699 2838').area_code).to be_nil
    end

    it 'should return area code if number is geo' do
      expect(Phonelib.parse('+16502530000').area_code).to eq('650')
      expect(Phonelib.parse('+18002530000').area_code).to be_nil
      expect(Phonelib.parse('+442070313000').area_code).to eq('20')
      expect(Phonelib.parse('+447912345678').area_code).to be_nil
      expect(Phonelib.parse('+61236618300').area_code).to eq('2')
      expect(Phonelib.parse('+390236618300').area_code).to eq('02')
      expect(Phonelib.parse('+6565218000').area_code).to be_nil
      expect(Phonelib.parse('+1650253000').area_code).to be_nil
      expect(Phonelib.parse('+80012345678').area_code).to be_nil
      expect(Phonelib.parse('+61236618300').area_code).to eq('2')
      expect(Phonelib.parse('+5491132277150').area_code).to eq('11')

    end
  end

  context 'local_number method' do
    it 'should return local number' do
      expect(Phonelib.parse('+61 3 9876 0010').local_number).to eq('9876 0010')
      expect(Phonelib.parse('+44 (0) 20-7031-3000').local_number).to eq('7031 3000')
      expect(Phonelib.parse('+852 2699 2838').local_number).to eq('2699 2838')
    end
  end

  context 'phone with extension' do
    it 'should parse phone as valid' do
      %w(972542234567#123 972542234567#ext=123 972542234567;123
         972542234567;ext=123 972542234567#12;3 972542234567;1#23).each do |p|

        phone = Phonelib.parse(p)
        expect(phone.valid?).to be true
        expect(phone.e164).to eq('+972542234567')
        expect(phone.extension).to eq('123')
        expect(phone.full_e164).to eq('+972542234567;123')
        expect(phone.full_international).to eq('+972 54-223-4567;123')
        expect(phone.full_national).to eq('054-223-4567;123')
      end
    end

    it 'should return nil if extension was not passed' do
      phone = Phonelib.parse('972542234567')
      expect(phone.valid?).to be true
      expect(phone.extension).to eq('')
      expect(phone.full_e164).to eq('+972542234567')
    end

    it 'should sanitize extension' do
      phone = Phonelib.parse('972542234567#sdfsdf')
      expect(phone.valid?).to be true
      expect(phone.extension).to eq('')
    end

    it 'should set different extension separator' do
      Phonelib.extension_separator = '#'

      phone = Phonelib.parse('972542234567#123')
      expect(phone.valid?).to be true
      expect(phone.e164).to eq('+972542234567')
      expect(phone.extension).to eq('123')
      expect(phone.full_e164).to eq('+972542234567#123')
      expect(phone.full_international).to eq('+972 54-223-4567#123')
    end
  end

  context 'issue #59' do
    it 'should be invalid if parse_special is false' do
      expect(Phonelib.parse_special).to be false
      expect(Phonelib.valid?("really1511@now.com")).to be false
    end

    it 'should be valid if parse_special is true' do
      Phonelib.parse_special = true
      expect(Phonelib.parse_special).to be true
      expect(Phonelib.valid?("really1511@now.com")).to be true
    end
  end

  context 'issue #61' do
    it 'should be valid number in India' do
      phone = Phonelib.parse('9111844757')
      expect(phone.valid?).to be true
      expect(phone.sanitized).to eq('9111844757')
      expect(phone.e164).to eq('+919111844757')
      expect(Phonelib.valid?('919111844757')).to be true

      phone = Phonelib.parse('49266444201')
      expect(phone.valid?).to be true
      expect(phone.sanitized).to eq('49266444201')
      expect(phone.e164).to eq('+49266444201')
      phone = Phonelib.parse('4949266444201')
      expect(phone.valid?).to be true
      expect(phone.sanitized).to eq('4949266444201')
      expect(phone.e164).to eq('+4949266444201')
    end
  end

  context 'issue #60' do
    it 'should be valid for CN with national prefix' do
      expect(Phonelib.valid_for_country?('2987388888', 'CN')).to be true
      expect(Phonelib.valid_for_country?('02987388888', 'CN')).to be true
    end
  end

  context 'issue #67' do
    it 'should parse CA numbers as valid numbers' do
      expect(Phonelib.parse('3065555555', 'CA').valid?).to be true
      expect(Phonelib.parse('4165555555', 'CA').valid?).to be true
    end
  end

  context 'issue #70' do
    after :each do
      Phonelib.strict_check = false
    end

    it 'should be invalid if strict_check is true' do
      Phonelib.strict_check = true
      expect(Phonelib.valid?("1212a5551234")).to be false
    end

    it 'should be valid if strict_check is false' do
      expect(Phonelib.strict_check).to be false
      expect(Phonelib.valid?("1212a5551234")).to be true
    end

    it 'should be valid if strict_check is true' do
      Phonelib.strict_check = true
      expect(Phonelib.valid?("12125551234")).to be true
    end
  end

  context 'issue #72' do
    it 'should be invalid number' do
      expect(Phonelib.parse('+49157123456789', 'de').international).to eq('+49157123456789')
      expect(Phonelib.parse('+49157123456789', 'de').valid?).to be false
    end

    it 'should not try to detect double prefix and keep invalid' do
      expect(Phonelib.parse('+491521234567', 'de').international).to eq('+491521234567')
      expect(Phonelib.parse('+491521234567', 'de').valid?).to be false
    end

    it 'should try to detect country and change it' do
      expect(Phonelib.parse('+521234567891', 'de').international).to eq('+521234567891')
      expect(Phonelib.parse('+521234567891', 'de').country).to eq('MX')
    end

    it 'should be invalid numbers without + and when country passed' do
      expect(Phonelib.parse('49157123456789', 'de').international).to eq('+49157123456789')
      expect(Phonelib.parse('49157123456789', 'de').valid?).to be false
      expect(Phonelib.parse('491521234567', 'de').international).to eq('+49 491 521234567')
      expect(Phonelib.parse('491521234567', 'de').valid?).to be true
    end

    it 'should try to detect when default country set but not passed' do
      Phonelib.default_country = :de
      expect(Phonelib.parse('49157123456789').international).to eq('+49157123456789')
      expect(Phonelib.parse('49157123456789').valid?).to be false
      expect(Phonelib.parse('491521234567').international).to eq('+49 491 521234567')
      expect(Phonelib.parse('491521234567').valid?).to be true
    end
  end

  context 'issue #75' do
    it 'should return e164 with country code' do
      Phonelib.default_country = :us
      expect(Phonelib.parse('7876711234').e164).to eq('+17876711234')
      expect(Phonelib.parse('7876711234').valid?).to be false
      Phonelib.default_country = :pr
      expect(Phonelib.parse('7876711234').e164).to eq('+17876711234')
      expect(Phonelib.parse('7876711234').valid?).to be true
    end
  end

  context 'issue #77' do
    it 'should not throw error' do
      expect(Phonelib.parse('1').e164).to eq('+1')
    end
  end

  context 'issues #76 and #78' do
    it 'should parse with right countries with default country' do
      Phonelib.default_country = :us

      expect(Phonelib.parse('+6465550123').e164).to eq('+6465550123')
      expect(Phonelib.parse('+47 904 48 617').country).to eq('NO')
      expect(Phonelib.parse('+47 924 48 617').country).to eq('NO')
    end
  end

  context 'issues ##81' do
    it 'should not raise errors for non-string inputs' do
      Phonelib.default_country = :nz

      expect{Phonelib.parse(6421555444)}.to_not raise_error
    end
  end

  context 'issue #83' do
    it 'should not throw error' do
      Phonelib.strict_check = true
      expect{Phonelib.parse(';')}.not_to raise_error
      Phonelib.strict_check = false
    end
  end

  context 'issue #80' do
    it 'should return right area code' do
      expect(Phonelib.parse('+15306355653').area_code).to eq('530')
    end
  end

  context 'issue #79' do
    it 'should be valid number for claro colombia' do
      expect(Phonelib.parse('+573234827533').valid?).to be true
      expect(Phonelib.parse('+573202605272').valid?).to be true
    end
  end

  context 'issue #85' do
    it 'should validate without strict and sanitize non numbers' do
      expect(Phonelib.valid?('441684291707')).to be true
      expect(Phonelib.valid?('+441684291707')).to be true
      expect(Phonelib.valid?('+4416842917076')).to be false
      expect(Phonelib.valid?('+441684291707x')).to be true
      expect(Phonelib.valid?('+441684291707xxxxxxxxxxxxxxxxxasdasadadas')).to be true
    end

    it 'should validate right with strict and sanitize only first +' do
      Phonelib.strict_check = true

      expect(Phonelib.valid?('441684291707')).to be true
      expect(Phonelib.valid?('+441684291707')).to be true
      expect(Phonelib.valid?('+4416842917076')).to be false
      expect(Phonelib.valid?('+441684291707x')).to be false
      expect(Phonelib.valid?('+441684291707xxxxxxxxxxxxxxxxxasdasadadas')).to be false

      Phonelib.strict_check = false
    end
  end

  context 'issue #87' do
    it 'should parse double IT country prefix' do
      expect(Phonelib.parse('3911234567', 'IT').national(false)).to eq('3911234567')
      expect(Phonelib.parse('3911234567', 'IT').valid?).to be true
      expect(Phonelib.parse('3911234567', 'IT').type).to eq(:mobile)

      expect(Phonelib.parse('+393911234567', 'IT').national(false)).to eq('3911234567')
      expect(Phonelib.parse('+393911234567', 'IT').valid?).to be true
      expect(Phonelib.parse('+393911234567', 'IT').type).to eq(:mobile)

      expect(Phonelib.parse('3921234567', 'IT').type).to eq(:mobile)
      expect(Phonelib.parse('3921234567', 'IT').national(false)).to eq('3921234567')
      expect(Phonelib.parse('3921234567', 'IT').valid?).to be true

      expect(Phonelib.parse('39391234', 'IT').valid?).to be false
      expect(Phonelib.parse('39391234', 'IT').possible?).to be true
    end
  end

  context 'issue #88' do
    it 'should return raw national number when valid' do
      phone = Phonelib.parse('+97221234567')
      expect(phone.raw_national).to eq('21234567')
      expect(phone.national).to eq('02-123-4567')
    end

    it 'should return raw national number when invalid' do
      phone = Phonelib.parse('+97221')
      expect(phone.raw_national).to eq('97221')
      expect(phone.national).to eq('97221')
    end

    it 'should return raw national number when possible' do
      phone = Phonelib.parse('+9721111111')
      expect(phone.raw_national).to eq('1111111')
      expect(phone.national).to eq('1111111')
    end
  end

  context 'issue #90' do
    it 'should return same results' do
      Phonelib.default_country = 'US'
      number = '4035566466'
      expect(Phonelib.possible?(number)).to be true
      expect(Phonelib.parse(number).possible?).to be true
      expect(Phonelib.parse(number, Phonelib.default_country).possible?).to be true
    end
  end

  context 'issue #100 - for country NO' do
    cell_numbers = [
        # Control examples
        '95098471', '41044927', '92859554',
        # Numbers starting with 47 without problems
        '47465724', '47944424', '47898180',
        # Numers starting with 471 with problems
        '47144752', '47152183', '47140633'
    ].freeze

    cell_numbers.each do |number|
      context "with phone number #{number}" do
        before :all do
          @number = number
          @phone = Phonelib.parse(@number, 'NO')
        end

        it 'should be valid' do
          expect(@phone.valid?).to be true
        end

        it 'should have right national' do
          expect(@phone.national(false)).to eq(@number)
        end

        it 'should have right e164' do
          expect(@phone.e164).to eq("+47#{@number}")
        end
      end
    end
  end

  context 'issue #102 vanity numbers' do
    it 'should be invalid' do
      expect(Phonelib.vanity_conversion).to be false

      p = Phonelib.parse('800-44-STERN', 'US')
      expect(p.valid?).to be false
    end

    it 'should be invalid' do
      Phonelib.vanity_conversion = true

      p = Phonelib.parse('800-44-STERN', 'US')
      expect(p.valid?).to be true
      expect(p.e164).to eq('+18004478376')
    end
  end

  context 'issue #103 to_s method' do
    it 'should return e164 if valid' do
      expect(Phonelib.parse('441684291707').to_s).to eq('+441684291707')
    end

    it 'should return original if invalid' do
      expect(Phonelib.parse('+442244').to_s).to eq('+442244')
    end
  end

  context 'issue #105' do
    it 'should be valid when original without +' do
      expect(Phonelib.valid?('9183082081')).to be true
      expect(Phonelib.valid_for_country?('9183082081', 'IN')).to be true
    end

    it 'should be invalid when original starts with +' do
      expect(Phonelib.valid?('+9183082081')).to be false
      expect(Phonelib.valid_for_country?('+9183082081', 'IN')).to be false
    end
  end

  context 'issue #107' do
    it 'should return consistent results for `valid_for_country?` when using the ' +
       'instance method or the class method given the same country and phone number' do
      phone_number = '0251092275'
      Phonelib.phone_data.keys.each do |country|
        expect(Phonelib.valid_for_country?(phone_number, country)).to(
          eq(Phonelib.parse(phone_number).valid_for_country?(country))
        )
      end
    end
  end

  context 'issue #132' do
    it 'should simplify national prefix and make phone valid' do
      phone = Phonelib.parse '0445532231113', 'MX'
      expect(phone.valid?).to be true
      expect(phone.international).to eq('+52 55 3223 1113')
      expect(phone.country).to eq('MX')
    end
  end

  context 'issue #133' do
    it 'should parse all numbers with extensions correctly' do
      Phonelib.extension_separate_symbols = %w(ext ; # extension)
      ['+1 212-555-5555 ext. 5555', '+1 212-555-5555;5555', '+1 212-555-5555#5555',
       '+1 212-555-5555 extension 5555'].each do |num|

        phone = Phonelib.parse(num)
        expect(phone.valid?).to be true
        expect(phone.international).to eq('+1 212-555-5555')
        expect(phone.extension).to eq('5555')
      end
    end
  end

  context 'issue #135' do
    it 'should be valid numbers for poland with double country prefix' do
      Phonelib.default_country = 'PL'

      %w(716287061 486287061).each do |phone|
        expect(Phonelib.parse(phone).valid?).to be true
        expect(Phonelib.parse("+48#{phone}").valid?).to be true
      end
      Phonelib.default_country = nil
    end
  end

  context 'issue #127' do
    it 'should be valid numbers for india starting with 6' do
      expect(Phonelib.parse('916000123456').valid?).to be true
      expect(Phonelib.parse('916000123456').valid?).to be true
    end
  end

  context 'issue #138' do
    it 'allowing 00 as international prefix' do
      expect(Phonelib.parse('0012015550123').valid?).to be true
      expect(Phonelib.parse('0012015550123').country).to eq('US')
      expect(Phonelib.parse('00441684291707').valid?).to be true
      expect(Phonelib.parse('00441684291707').country).to eq('GB')
    end
  end

  context 'issue #140' do
    it 'should be valid numbers for india with default country' do
      Phonelib.default_country = 'IN'

      expect(Phonelib.parse('8340412345').valid?).to be true
      expect(Phonelib.parse('7970012345').valid?).to be true

      Phonelib.default_country = nil
    end
  end

  # https://github.com/daddyz/phonelib/issues/157
  describe 'equality' do
    let(:parsed_number) { Phonelib.parse(raw_number) }
    let(:raw_number) { '281-330-8004' }

    before { Phonelib.default_country = 'US' }
    after { Phonelib.default_country = nil }

    context 'when given a number as a string' do
      it 'is equal' do
        expect(parsed_number).to eq raw_number
      end
    end

    context 'when given identical parsed numbers' do
      it 'is equal' do
        expect(parsed_number).to eq Phonelib.parse(raw_number)
      end
    end

    context 'when given different representations of the same number' do
      it 'is equal' do
        expect(parsed_number).to eq raw_number.tr('-', '')
      end
    end

    context 'when given different numbers' do
      it 'is not equal' do
        expect(parsed_number).not_to eq '281-330-8005'
      end
    end

    context 'when numbers are invalid' do
      it 'should not be equal' do
        p1 = Phonelib.parse('+12121231234')
        expect(parsed_number).not_to eq p1
      end
    end
  end

  context 'issue #161' do
    before do
      Phonelib.strict_double_prefix_check = false
    end

    context 'when strict_double_prefix_check is false' do
      it 'should be valid number outside the country' do
        Phonelib.default_country = nil
        phone = Phonelib.parse('9111844757')
        expect(phone.valid?).to be true
        expect(Phonelib.valid?('919111844757')).to be true
      end

      it 'should be valid number inside the country' do
        phone = Phonelib.parse('9111844757', 'IN')
        expect(phone.valid?).to be true
        expect(Phonelib.valid?('919111844757')).to be true

        Phonelib.default_country = 'IN'
        phone = Phonelib.parse('9111844757')
        expect(phone.valid?).to be true
      end
    end

    context 'when strict_double_prefix_check is true' do
      before do
        Phonelib.strict_double_prefix_check = true
      end

      it 'should be invalid number outside the country' do
        Phonelib.default_country = nil
        phone = Phonelib.parse('9111844757')
        expect(phone.valid?).to be false
        expect(Phonelib.valid?('919111844757')).to be true
      end

      it 'should be valid number inside the country' do
        phone = Phonelib.parse('9111844757', 'IN')
        expect(phone.valid?).to be true
        expect(Phonelib.valid?('919111844757')).to be true

        Phonelib.default_country = 'IN'
        phone = Phonelib.parse('9111844757')
        expect(phone.valid?).to be true
      end
    end
  end

  context 'valid_country_name method' do
    it 'should not return name for invalid number' do
      phone = Phonelib.parse('+12121231234')
      expect(phone.valid?).to be false
      expect(phone.valid_country_name).to be nil
    end

    it 'should return valid country name' do
      phone = Phonelib.parse('+12125551234')
      expect(phone.valid?).to be true
      expect(phone.valid_country_name).to eq('United States')
    end
  end

  context 'issue #143' do
    it 'should be valid barbados number' do
      expect(Phonelib.parse('1-246-753-8358', 'BB').valid?).to be true
    end
  end

  context 'prefix to international and e164 methods' do
    it 'should accept prefix in international' do
      phone = Phonelib.parse('+12125551234;99')
      expect(phone.valid?).to be true
      expect(phone.international).to eq('+1 212-555-1234')
      expect(phone.international(true, '00')).to eq('001 212-555-1234')
      expect(phone.international('00')).to eq('001 212-555-1234')
      expect(phone.international_00).to eq('001 212-555-1234')
      expect(phone.full_international('00')).to eq('001 212-555-1234;99')
      expect(phone.full_international_00).to eq('001 212-555-1234;99')
    end

    it 'should accept prefix in e164' do
      phone = Phonelib.parse('+12125551234;99')
      expect(phone.valid?).to be true
      expect(phone.e164).to eq('+12125551234')
      expect(phone.e164('00')).to eq('0012125551234')
      expect(phone.e164_00).to eq('0012125551234')
      expect(phone.full_e164('00')).to eq('0012125551234;99')
      expect(phone.full_e164_00).to eq('0012125551234;99')
    end

    it 'should raise error if bad method name passed' do
      phone = Phonelib.parse('+12125551234;99')
      expect { phone.fff_00 }.to raise_error(NameError)
    end
  end

  context 'issue #160' do
    it 'should return international number when intl_format is NA' do
      n = Phonelib.parse('+61 13 12 21', 'au')
      expect(n.valid?).to be(true)
      expect(n.full_international).to eq('+61 131221')
    end

    it 'should use intl_format if it is good' do
      p = Phonelib.parse('+12125551234')
      expect(p.valid?).to be(true)
      expect(p.international).to eq('+1 212-555-1234')
      expect(p.national).to eq('(212) 555-1234')
    end
  end

  context 'issue #152' do
    it 'should return correct format for MX' do
      p = Phonelib.parse('0459991234567', 'MX')
      expect(p.national).to eq('999 123 4567')
    end
  end

  context 'issue #171' do
    it 'should return correct format for VN' do
      p = Phonelib.parse('902962207', 'VN')
      expect(p.international).to eq('+84 90 296 22 07')
      p = Phonelib.parse('844666531', 'VN')
      expect(p.international).to eq('+84 844 666 531')
    end
  end

  context 'issue #203' do
    it 'should be valid when sanitize all symbols' do
      p = Phonelib.parse('+1 (713) 555-1212 ; abc')
      expect(p.valid?).to be(true)
    end

    it 'should be invalid when sanitize only valuable symbols' do
      Phonelib.sanitize_regex = '[\.\-\(\) \;\+]'
      p = Phonelib.parse('+1 (713) 555-1212 ; abc')
      expect(p.valid?).to be(true)
    end

    it 'should be valid when sanitize only valuable symbols' do
      old = Phonelib.sanitize_regex
      Phonelib.sanitize_regex = '[\.\-\(\) \;\+]'
      p = Phonelib.parse('+1 (713) 555-1212')
      expect(p.valid?).to be(true)
      Phonelib.sanitize_regex = old
    end
  end

  context 'additional_regexes' do
    before(:each) do
      Phonelib.additional_regexes = []
    end

    after(:each) do
      Phonelib.additional_regexes = []
    end

    it 'should parse number as valid' do
      phone = '+1-000-000-0000'
      expect(Phonelib.additional_regexes).to eq({})
      p1 = Phonelib.parse(phone)
      expect(p1.valid?).to be(false)
      Phonelib.add_additional_regex :us, Phonelib::Core::MOBILE, '0{10}'
      p2 = Phonelib.parse(phone)
      expect(p2.valid?).to be(true)
      expect(p2.possible?).to be(true)
      expect(p2.international).to eq('+1 000 000 0000')
      expect(p2.country).to eq('US')
    end

    it 'dump correct' do
      Phonelib.additional_regexes = []
      expect(Phonelib.additional_regexes).to eq({})
      Phonelib.add_additional_regex :us, Phonelib::Core::MOBILE, '0{10}'
      Phonelib.add_additional_regex :us, Phonelib::Core::MOBILE, '1{10}'
      expect(Phonelib.dump_additional_regexes).to eq([['US', :mobile, '0{10}'], ['US', :mobile, '1{10}']])
    end

    it 'load correct' do
      expect(Phonelib.additional_regexes).to eq({})
      Phonelib.additional_regexes = [[:us, :mobile, '0{10}'], [:us, :mobile, '1{10}']]
      expect(Phonelib.dump_additional_regexes).to eq([['US', :mobile, '0{10}'], ['US', :mobile, '1{10}']])
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
      expect(phone.valid?).to be(true), "#{msg} not valid"
      expect(phone.invalid?).to be(false), "#{msg} not valid"
      expect(phone.possible?).to be(true), "#{msg} not possible"
      expect(phone.impossible?).to be(false), "#{msg} not possible"
      expect(phone.valid_for_country?(country)).to be(true),
             "#{msg} not valid for country"
      expect(phone.invalid_for_country?(country)).to be(false),
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
