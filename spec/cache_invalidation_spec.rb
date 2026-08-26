require 'phonelib'
require 'tempfile'

describe 'phone data overrides' do
  it 'rebuilds cached international-prefix patterns after an override' do
    original_override = Phonelib.override_phone_data
    original_data = Marshal.load(File.binread('data/phone_data.dat'))
    override_data = {
      'US' => original_data['US'].merge(international_prefix: '7654321')
    }
    override_file = Tempfile.new('phonelib-override')
    override_file.binmode
    Marshal.dump(override_data, override_file)
    override_file.close

    begin
      Phonelib.override_phone_data = nil
      Phonelib.phone_regexp_cache.clear
      Phonelib.parse('01116502530000')

      Phonelib.override_phone_data = override_file.path

      expect(Phonelib.parse('765432116502530000')).to be_valid
    ensure
      Phonelib.override_phone_data = original_override
      Phonelib.phone_regexp_cache.clear
      override_file.unlink
    end
  end
end
