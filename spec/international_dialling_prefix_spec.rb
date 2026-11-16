require 'phonelib'

describe 'International dialling prefixes' do
  before do
    @default_country = Phonelib.default_country
    Phonelib.default_country = nil
    data = Phonelib.phone_data.fetch('NL')
    @destination = data[:country_code] + data[:types][:mobile][:example_number]
  end

  after do
    Phonelib.default_country = @default_country
  end

  { 'AU' => '0011', 'KE' => '000', 'TZ' => '000', 'UG' => '000', 'NG' => '009' }.each do |country, prefix|
    it "parses #{country}'s international prefix with an explicit country" do
      phone = Phonelib.parse(prefix + @destination, country)
      expect(phone.valid?).to eq(true)
      expect(phone.country).to eq('NL')
      expect(phone.e164).to eq('+' + @destination)
    end

    it "parses #{country}'s international prefix with a default country" do
      Phonelib.default_country = country
      phone = Phonelib.parse(prefix + @destination)
      expect(phone.valid?).to eq(true)
      expect(phone.country).to eq('NL')
      expect(phone.e164).to eq('+' + @destination)
    end
  end

  it 'uses a matching international prefix among default countries' do
    Phonelib.default_country = ['US', 'AU']
    expect(Phonelib.parse('0011' + @destination).e164).to eq('+' + @destination)
  end

  it 'continues to detect plus and double-zero international input' do
    ['+' + @destination, '00' + @destination].each do |input|
      expect(Phonelib.parse(input, 'US').e164).to eq('+' + @destination)
    end
  end

  it 'does not interpret a plus-prefixed number as the origin country IDD' do
    expect(Phonelib.parse('+0011' + @destination, 'AU').valid?).to eq(false)
  end

  context 'with a default country whose international prefix is 00' do
    before { Phonelib.default_country = 'FR' }

    # NC and AD numbers whose digits after 00 also form a valid FR national number
    { 'NC' => :mobile, 'AD' => :fixed_line }.each do |country, type|
      it "reads the digits after 00 as #{country}'s country code, not as a FR number" do
        data = Phonelib.phone_data.fetch(country)
        international = data[:country_code] + data[:types][type][:example_number]
        phone = Phonelib.parse('00' + international)
        expect(phone.country).to eq(country)
        expect(phone.e164).to eq('+' + international)
      end
    end

    it 'does not read an invalid international number as a national number of another country' do
      # a DE mobile one digit short: invalid, but 0049… is also a valid DE national number
      international = '49' + Phonelib.phone_data.fetch('DE')[:types][:mobile][:example_number][0..-2]
      phone = Phonelib.parse('00' + international)
      expect(phone.valid?).to eq(false)
      expect(phone.e164).to eq('+' + international)
    end

    it 'still reads a mistyped national number with an extra leading 0 in the default country' do
      phone = Phonelib.parse('00' + Phonelib.phone_data.fetch('FR')[:types][:mobile][:example_number])
      expect(phone.country).to eq('FR')
      expect(phone.valid?).to eq(true)
    end

    it 'reads the digits after 00 as an international number with the default country passed explicitly' do
      data = Phonelib.phone_data.fetch('AD')
      international = data[:country_code] + data[:types][:fixed_line][:example_number]
      phone = Phonelib.parse('00' + international, 'FR')
      expect(phone.country).to eq('AD')
      expect(phone.e164).to eq('+' + international)
    end
  end

  # TD dials out with 00 or 16, KP with 00 or 99
  { 'TD' => 'TC', 'KP' => 'TJ' }.each do |default_country, country|
    it "does not strip #{default_country}'s other international prefix from the digits after 00" do
      Phonelib.default_country = default_country
      data = Phonelib.phone_data.fetch(country)
      international = data[:country_code] + data[:types][:mobile][:example_number]
      phone = Phonelib.parse('00' + international)
      expect(phone.country).to eq(country)
      expect(phone.e164).to eq('+' + international)
    end
  end

  it 'retains the country for the all-zero national input from issue 363' do
    expect(Phonelib.parse('0000000000', 'US').possible?).to eq(true)
  end

  context 'national numbers starting with 00' do
    it 'parses a JP toll-free number with an explicit country' do
      ["0037-012-345", "0066-812-345", "0078-512-345", "0037-6123-45678"].each do |input|
        phone = Phonelib.parse(input, 'JP')
        expect(phone.valid?).to eq(true)
        expect(phone.country).to eq('JP')
        expect(phone.type).to eq(:toll_free)
        expect(phone.e164).to eq("+81#{input.gsub(/[^0-9]/, '')}")
        expect(phone.national).to eq(input)
      end
    end

    it 'parses a JP toll-free number with a default country' do
      Phonelib.default_country = 'JP'
      phone = Phonelib.parse('0066812345')
      expect(phone.valid?).to eq(true)
      expect(phone.country).to eq('JP')
    end

    it 'keeps the number invalid without a country' do
      expect(Phonelib.parse('0066812345').valid?).to eq(false)
    end

    it 'keeps the number invalid when it is not national for the passed country' do
      expect(Phonelib.parse('0066812345', 'US').valid?).to eq(false)
    end

    it 'prefers a valid international reading over the national one' do
      phone = Phonelib.parse('00370 611 11 111', 'JP')
      expect(phone.country).to eq('LT')
      expect(phone.e164).to eq('+37061111111')
    end
  end
end
