require 'test_helper'

class PhonelibTest < Test::Unit::TestCase

  should 'be a Module' do
    assert_kind_of Module, Phonelib
  end

  context '.parse' do
    setup { @phone = Phonelib.parse '9721234567' }

    should 'return a Phone object' do
      assert @phone.is_a? Phonelib::Phone #instance_of?
    end

    should 'be possible but not valid phone number' do
      assert !@phone.valid?
      assert @phone.possible?
    end

    context 'with international formatting' do
      setup { @phone = Phonelib.parse('+1 (972) 123-4567', 'US') }
      should 'return exact original' do
        assert_equal '+1 (972) 123-4567', @phone.original
      end
    end
  end

  context '.valid?' do
    context 'with malformed phone number' do
      should 'not be valid' do
        assert !Phonelib.valid?('sdffsd')
      end
    end

    context 'with valid phone number' do
      should 'be valid' do
        assert Phonelib.valid?('972541234567')
      end
    end

    context 'with invalid phone number' do
      should 'not be valid' do
        assert !Phonelib.valid?('97254123')
      end
    end
  end

  context '.invalid?' do
    context 'with malformed phone number' do
      should 'be valid' do
        assert Phonelib.invalid?('sdffsd')
      end
    end

    context 'with valid phone number' do
      should 'not be valid' do
        assert !Phonelib.invalid?('972541234567')
      end
    end

    context 'with invalid phone number' do
      should 'be valid' do
        assert Phonelib.invalid?('97254123')
      end
    end
  end

  context '.possible?' do
    context 'with valid phone number' do
      should 'be valid' do
        assert Phonelib.possible? '972541234567'
      end
    end

    context 'with invalid phone number' do
      should 'not be valid' do
        assert !Phonelib.possible?('97254123')
      end
    end
  end

  context '.impossible?' do
    context 'with valid phone number' do
      should 'not be valid' do
        assert !Phonelib.impossible?('972541234567')
      end
    end

    context 'with invalid phone number' do
      should 'be valid' do
        assert Phonelib.impossible?('97254123')
      end
    end
  end

  context 'valid_for_country?' do
    context 'with correct data' do
      ['IL', 'il', :il].each do |country|
        context "with #{country} as country" do
          should 'be valid' do
            assert Phonelib.valid_for_country?('972541234567', country)
          end

          context 'and national number' do
            should 'be valid' do
              assert Phonelib.valid_for_country?('0541234567', country)
            end
          end

          context 'and without prefix' do
            should 'be valid' do
              assert Phonelib.valid_for_country?('541234567', country)
            end
          end
        end
      end
    end

    ['US', 'us', :us].each do |country|
      context "with #{country} as country" do
        context 'with incorrect data' do
          should 'not be valid' do
            assert !Phonelib.valid_for_country?('972541234567', country)
          end

          context 'and without prefix' do
            should 'not be valid' do
              assert !Phonelib.valid_for_country?('541234567', country)
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
          should 'not be invalid' do
            assert !Phonelib.invalid_for_country?('972541234567', country)
          end
        end
      end
    end

    context 'with incorrect data' do
      ['US', 'us', :us].each do |country|
        context "with #{country} as country" do
          should 'be invalid' do
            assert Phonelib.invalid_for_country?('972541234567', country)
          end
        end
      end
    end
  end

  context '#international' do
    should 'return right formatting' do
      phone = Phonelib.parse('972541234567')
      assert_equal '+972 54-123-4567', phone.international
    end

    should 'return sanitized when number invalid but possible' do
      phone = Phonelib.parse('9721234567')
      assert_equal '+9721234567', phone.international
    end
  end

  context '#national' do
    should 'return right formatting' do
      phone = Phonelib.parse('972541234567')
      assert_equal '054-123-4567', phone.national
    end

    should 'return sanitized national when number invalid but possible' do
      phone = Phonelib.parse('9721234567')
      assert_equal '1234567', phone.national
    end

    should 'return without leading digit for CN number' do
      phone = Phonelib.parse('18621374266', 'CN')
      assert_equal '186 2137 4266', phone.national
    end
  end

  context 'types' do
    setup { @phone = Phonelib.parse('972541234567') }
    should 'return :mobile type' do
      assert_equal :mobile, @phone.type
    end

    should 'return Mobile human type' do
      assert_equal 'Mobile', @phone.human_type
    end

    should 'return [:mobile] as all types' do
      assert_equal [:mobile], @phone.types
    end

    should 'return [Mobile] as all human types' do
      assert_equal %w(Mobile), @phone.human_types
    end
  end

  context 'country' do
    should 'return IL as country' do
      phone = Phonelib.parse('972541234567')
      assert 'IL', phone.country
    end

    should 'return RU as country' do
      phone = Phonelib.parse('78005500500')
      assert 'RU', phone.country
    end
  end

  context 'default_country' do
    should 'be invalid with no default country set' do
      phone = Phonelib.parse('541234567')
      assert !phone.valid?
    end

    should 'valid with default country set' do
      Phonelib.default_country = :IL
      phone = Phonelib.parse('541234567')
      assert phone.valid?
    end

    should 'valid with wrong default country set' do
      Phonelib.default_country = :UA
      phone = Phonelib.parse('972541234567')
      assert phone.valid?
    end

    should 'not fail when no phone passed and default country set' do
      Phonelib.default_country = :UA
      phone = Phonelib.parse(nil)
      assert phone.invalid?
    end

    should 'be valid when number invalid for default country' do
      Phonelib.default_country = :CN
      phone = Phonelib.parse('+41 44 668 18 00')
      assert phone.valid?
    end
  end

  context 'issue #16' do
    should 'parse as LT country' do
      phone = Phonelib.parse('00370 611 11 111')
      assert_equal 'LT', phone.country
    end

    should 'show correct international' do
      phone = Phonelib.parse('370 611 11 111')
      assert_equal '+370 611 11111', phone.international
    end
  end
end
