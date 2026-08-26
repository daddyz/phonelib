require 'phonelib'

describe 'phone validation diagnostics' do
  before(:each) do
    Phonelib.default_country = nil
    Phonelib.extension_separate_symbols = '#;'
    Phonelib.parse_special = false
    Phonelib.strict_check = false
    Phonelib.vanity_conversion = false
    Phonelib.sanitize_regex = '[^0-9]+'
    Phonelib.ignore_plus = false
    Phonelib.strict_double_prefix_check = false
    Phonelib.additional_regexes = []
  end

  it 'explains a possible phone number that is not valid' do
    phone = Phonelib.parse('9721234567')

    expect(phone.errors.details).to eq([{ error: :invalid }])
    expect(phone.errors.messages).to eq(['is not a valid phone number'])
  end

  it 'distinguishes text that is not a phone number' do
    result = Phonelib.parse('This is not a phone number', 'NZ').validation

    expect(result.possibility).to eq(:impossible)
    expect(result.errors.details).to eq([{ error: :not_a_number }])
    expect(result.errors.messages).to eq(['is not a phone number'])
  end

  it 'rejects non-viable short input before possibility checks' do
    ['(1)', '+1', '+49', '1-2', '1 2', '1.2', '1x2'].each do |input|
      result = Phonelib.parse(input, 'US').validation(possible: true)

      expect(result.errors.details).to eq([{ error: :not_a_number }])
    end
  end

  it 'rejects nonnumeric strict-mode input before possibility checks' do
    Phonelib.strict_check = true

    result = Phonelib.parse('abc', 'US').validation(possible: true)

    expect(result.errors.details).to eq([{ error: :not_a_number }])
  end

  it 'allows surrounding punctuation on an otherwise viable two-digit input' do
    result = Phonelib.parse('(12)', 'US').validation(possible: true)

    expect(result.errors.first.code).to eq(:too_short)
  end

  it 'uses a conservative fallback when no country context can prove a cause' do
    result = Phonelib.parse('12345').validation(possible: true)

    expect(result.errors.details).to eq([{ error: :not_possible }])
  end

  it 'reports an unsupported international country calling code' do
    result = Phonelib.parse('+210 3456 56789', 'NZ').validation

    expect(result.errors.details).to eq(
      [{ error: :invalid_country_code }]
    )
  end

  it 'reports an unsupported region when a national number needs that context' do
    result = Phonelib.parse('6502530000', 'ZZ').validation

    expect(result.errors.details).to eq(
      [{ error: :invalid_country_code }]
    )
  end

  it 'preserves the parsed-phone result for an unsupported supplied region' do
    phone = Phonelib.parse('+1 6502530000', 'ZZ')
    result = phone.validation(possible: true)

    expect(phone.possible?).to be false
    expect(result).not_to be_valid
    expect(result.errors.details).to eq([
      { error: :not_possible, possibility: :possible }
    ])
  end

  it 'identifies a number that ends immediately after an international dialing prefix' do
    result = Phonelib.parse('011', 'US').validation

    expect(result.errors.details).to eq(
      [{ error: :too_short, actual_length: 0 }]
    )
  end

  it 'uses the configured default region to recognize an international dialing prefix' do
    Phonelib.default_country = 'US'

    result = Phonelib.parse('011').validation

    expect(result.errors.details).to eq(
      [{ error: :too_short, actual_length: 0 }]
    )
  end

  it 'identifies a national number that cannot contain enough digits' do
    result = Phonelib.parse('+49 0', 'DE').validation

    expect(result.errors.details).to eq(
      [{ error: :too_short, actual_length: 1 }]
    )
  end

  it 'reports when a parsed number is shorter than every regional possibility' do
    result = Phonelib.parse('+1 253000').validation(possible: true)

    expect(result.possibility).to eq(:impossible)
    expect(result.errors.details).to eq(
      [{
        error: :too_short,
        actual_length: 6,
        expected_lengths: [10]
      }]
    )
  end

  it 'uses the supplied region to diagnose a national number' do
    result = Phonelib.parse('253000', 'US').validation(possible: true)

    expect(result.errors.details).to eq(
      [{
        error: :too_short,
        actual_length: 6,
        expected_lengths: [10]
      }]
    )
  end

  it 'uses the country resolved from multiple default countries' do
    Phonelib.default_country = %w[US DE]
    phone = Phonelib.parse('30123456')
    result = phone.validation

    expect(phone.valid_countries).to eq(['DE'])
    expect(result).to be_valid
    expect(result.possibility).to eq(:possible)
  end

  it 'uses the country resolved from multiple explicitly passed countries' do
    phone = Phonelib.parse('30123456', %w[US DE])
    result = phone.validation

    expect(phone.valid_countries).to eq(['DE'])
    expect(result).to be_valid
    expect(result.possibility).to eq(:possible)
  end

  it 'uses the destination plan after a valid international dialing prefix' do
    result = Phonelib.parse('011 1 253000', 'US').validation(possible: true)

    expect(result.errors.details).to eq(
      [{
        error: :too_short,
        actual_length: 6,
        expected_lengths: [10]
      }]
    )
  end

  it 'uses parser country routing when ignoring a leading plus sign' do
    Phonelib.ignore_plus = true
    phone = Phonelib.parse('+119441234567', 'CU')

    expect(phone.country).to eq('GB')
    expect(phone).to be_possible
    expect(phone.validation(possible: true).possibility).to eq(:possible)
  end

  it 'reports when a parsed number is longer than every regional possibility' do
    result = Phonelib.parse('+1 65025300001').validation(possible: true)

    expect(result.errors.details).to eq(
      [{
        error: :too_long,
        actual_length: 11,
        expected_lengths: [10]
      }]
    )
  end

  it 'distinguishes the parser maximum from a regional too-long result' do
    result = Phonelib.parse('01495 72553301873 810104', 'GB').validation

    expect(result.errors.details).to eq(
      [{ error: :too_long, actual_length: 22 }]
    )
  end

  it 'classifies non-numeric raw input by its contents rather than byte length' do
    result = Phonelib.parse('x' * 251, 'US').validation

    expect(result.errors.details).to eq([{ error: :not_a_number }])
  end

  it 'does not contradict Phone#valid? because of raw formatting length' do
    number = '+1 6502530000'
    input = (' ' * (251 - number.length)) + number
    phone = Phonelib.parse(input)

    expect(phone).to be_valid
    expect(phone.validation).to be_valid
  end

  it 'accepts the parser raw input limit exactly' do
    number = '+1 6502530000'
    input = (' ' * (250 - number.length)) + number

    expect(Phonelib.parse(input).validation).to be_valid
  end

  it 'measures the parser maximum after removing a country calling code' do
    result = Phonelib.parse('+44 1234567890123456').validation(possible: true)

    expect(result.errors.details).to eq(
      [{
        error: :too_long,
        actual_length: 16,
        expected_lengths: [7, 9, 10]
      }]
    )
  end

  it 'uses parser-normalized national digits for international numbers' do
    phone = Phonelib.parse('+44 (0) 20-7031-3000')

    expect(phone).to be_valid
    expect(phone).to be_possible
    expect(phone.validation.possibility).to eq(:possible)
  end

  it 'reports a length between the regional bounds that is not permitted' do
    result = Phonelib.parse('+229 123456789').validation(possible: true)

    expect(result.errors.details).to eq(
      [{
        error: :invalid_length,
        actual_length: 9,
        expected_lengths: [8, 10]
      }]
    )
  end

  it 'reports a local-only possibility without changing Phone#possible?' do
    phone = Phonelib.parse('+49 12')
    result = phone.validation(possible: true)

    expect(phone.possible?).to be false
    expect(result.possibility).to eq(:possible_local_only)
    expect(result).not_to be_valid
    expect(result.errors.details).to eq([
      { error: :not_possible, possibility: :possible_local_only }
    ])
  end

  it 'prefers a normal possibility when another type uses that length locally' do
    result = Phonelib.parse('+49 1234').validation(possible: true)

    expect(result.possibility).to eq(:possible)
    expect(result).to be_valid
  end

  it 'uses the main region for possibility under a shared calling code' do
    phone = Phonelib.parse('+1 3101234')
    result = phone.validation(possible: true)

    expect(phone.possible?).to be true
    expect(result.possibility).to eq(:possible_local_only)
    expect(result).to be_valid
  end

  it 'reports intrinsic local-only failure before country policy errors' do
    result = Phonelib.parse('+49 12').validation(
      possible: true,
      countries: :de
    )

    expect(result.errors.details).to eq([
      { error: :not_possible, possibility: :possible_local_only }
    ])
  end

  it 'honors runtime regexes that extend the imported possibility metadata' do
    Phonelib.add_additional_regex(:us, :mobile, '0{5}')
    phone = Phonelib.parse('+1 00000')

    expect(phone.possible?).to be true
    expect(phone.validation(possible: true)).to be_valid
    expect(phone.validation(possible: true).possibility).to eq(:possible)
  end

  it 'prefers a runtime regex possibility over a local-only length' do
    Phonelib.add_additional_regex(:de, :mobile, '12')
    phone = Phonelib.parse('+49 12')

    expect(phone).to be_possible
    expect(phone.validation(possible: true).possibility).to eq(:possible)
  end

  it 'keeps possibility consistent with the configuration used for parsing' do
    phone = Phonelib.parse('+1 00000')
    expect(phone).not_to be_possible

    Phonelib.add_additional_regex(:us, :mobile, '0{5}')
    result = phone.validation(possible: true)

    expect(result.possibility).to eq(:impossible)
    expect(result).not_to be_valid
  end

  it 'honors special-number parsing outside the general length metadata' do
    Phonelib.parse_special = true
    phone = Phonelib.parse('911', 'US')

    expect(phone.possible?).to be true
    expect(phone.validation(possible: true).possibility).to eq(:possible)
    expect(phone.validation(possible: true)).to be_valid
  end

  it 'uses a generic invalid error when length is possible but the pattern is not valid' do
    result = Phonelib.parse('+54 12345678901').validation

    expect(result.possibility).to eq(:possible)
    expect(result.errors.details).to eq([{ error: :invalid }])
  end

  it 'represents a valid number as a successful result rather than an error code' do
    result = Phonelib.parse('+1 6502530000').validation

    expect(result.possibility).to eq(:possible)
    expect(result).to be_valid
    expect(result.error).to be_nil
  end

  it 'raises for invalid validation configuration rather than blaming the phone' do
    phone = Phonelib.parse('+1 6502530000')

    expect { phone.validation(possible: :yes) }.to raise_error(
      ArgumentError,
      'possible must be true or false'
    )
  end

  it 'rejects unknown validation options' do
    phone = Phonelib.parse('+1 6502530000')

    expect { phone.validation(typo: true) }.to raise_error(
      ArgumentError,
      'unknown validation option: typo'
    )
  end

  it 'requires an explicit boolean extension policy' do
    phone = Phonelib.parse('+1 6502530000')

    expect { phone.validation(extensions: :forbid) }.to raise_error(
      ArgumentError,
      'extensions must be true or false'
    )
  end

  it 'rejects malformed type collections' do
    phone = Phonelib.parse('+1 6502530000')

    expect { phone.validation(types: { mobile: true }) }.to raise_error(
      ArgumentError,
      'types must be a symbol, string, or array of them'
    )
  end

  it 'rejects unknown phone types before normalizing them' do
    phone = Phonelib.parse('+1 6502530000')

    expect { phone.validation(types: 'external_type') }.to raise_error(
      ArgumentError,
      'unknown phone type: external_type'
    )
  end

  it 'bounds validation collections' do
    phone = Phonelib.parse('+1 6502530000')

    expect { phone.validation(countries: Array.new(301, 'US')) }.to raise_error(
      ArgumentError,
      'countries must contain at most 300 values'
    )
  end

  it 'rejects unknown validation error codes without allocating symbols' do
    expect { Phonelib::ValidationError.new('external_error') }.to raise_error(
      ArgumentError,
      'unknown validation error code: external_error'
    )
  end

  it 'renders messages through an optional framework-independent translator' do
    errors = Phonelib.parse('+1 253000').errors(possible: true)
    translator = lambda do |key, default:, **values|
      "#{key}: #{values[:actual_length]} digits (#{default})"
    end

    expect(errors.messages(translator: translator)).to eq(
      ['phonelib.errors.too_short: 6 digits (is too short)']
    )
  end

  it 'returns immutable diagnostic snapshots' do
    errors = Phonelib.parse('+44 20 7946 0018').errors(types: :mobile)
    details = errors.details

    expect(details).to be_frozen
    expect(details.first).to be_frozen
    expect(details.first[:matched_types]).to be_frozen
    expect { details.first[:matched_types] << :mobile }.to raise_error(FrozenError)
  end

  it 'reports every independent policy violation after intrinsic validation passes' do
    phone = Phonelib.parse('+44 20 7946 0018;42')

    result = phone.validation(
      types: :mobile,
      countries: :US,
      extensions: false
    )

    expect(result.errors.details).to eq(
      [
        {
          error: :type_not_allowed,
          allowed_types: [:mobile],
          matched_types: [:fixed_line]
        },
        {
          error: :country_not_allowed,
          allowed_countries: ['US'],
          matched_countries: ['GB']
        },
        { error: :extension_not_allowed, extension_present: true }
      ]
    )
  end

  it 'treats an empty allowed collection as an unsatisfiable policy' do
    phone = Phonelib.parse('+1 6502530000')

    result = phone.validation(types: [], countries: [])

    expect(result.errors.details).to eq(
      [
        {
          error: :type_not_allowed,
          allowed_types: [],
          matched_types: [:fixed_or_mobile]
        },
        {
          error: :country_not_allowed,
          allowed_countries: [],
          matched_countries: ['US']
        }
      ]
    )
  end
end
