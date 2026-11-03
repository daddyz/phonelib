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
