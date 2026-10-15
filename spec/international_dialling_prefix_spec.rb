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
end
