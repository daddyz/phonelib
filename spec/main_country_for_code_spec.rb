require 'phonelib'

describe 'Main country for shared country codes' do
  before do
    @default_country = Phonelib.default_country
    Phonelib.default_country = nil
  end

  after do
    Phonelib.default_country = @default_country
  end

  it 'does not check other +1 countries when the number is valid for US' do
    ['+18002123456', '18002123456', '+12015550123'].each do |input|
      phone = Phonelib.parse(input)
      expect(phone.valid?).to eq(true)
      expect(phone.country).to eq('US')
      expect(phone.countries).to eq(['US'])
      expect(phone.valid_countries).to eq(['US'])
    end
  end

  it 'does not check other +61 countries when the number is valid for AU' do
    phone = Phonelib.parse('+61412345678')
    expect(phone.country).to eq('AU')
    expect(phone.countries).to eq(['AU'])
  end

  it 'falls back to other countries sharing the code when the main country is not valid' do
    { '+12684601234' => 'AG', '+16135550123' => 'CA', '+61891621234' => 'CC', '+447797712345' => 'JE' }.each do |input, iso2|
      phone = Phonelib.parse(input)
      expect(phone.valid?).to eq(true)
      expect(phone.country).to eq(iso2)
      expect(phone.valid_countries).to eq([iso2])
      expect(phone.countries.size).to be > 1
    end
  end

  it 'checks all countries sharing the code when the number is only possible for the main country' do
    { '+12001234567' => ['US', 25], '+61012345678' => ['AU', 3] }.each do |input, (iso2, size)|
      phone = Phonelib.parse(input)
      expect(phone.valid?).to eq(false)
      expect(phone.possible?).to eq(true)
      expect(phone.country).to eq(iso2)
      expect(phone.countries.size).to eq(size)
      expect(phone.valid_countries).to eq([])
    end
  end

  it 'keeps the passed country' do
    phone = Phonelib.parse('+18002123456', 'CA')
    expect(phone.country).to eq('CA')
    expect(phone.countries).to eq(['CA'])
  end
end
