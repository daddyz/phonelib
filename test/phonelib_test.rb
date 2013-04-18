require 'test_helper'

class PhonelibTest < ActiveSupport::TestCase
  test "truth" do
    assert_kind_of Module, Phonelib
  end

  test "returns phone object" do
    assert Phonelib.parse('972541234567').is_a? Phonelib::Phone
  end

  test "valid? with malformed phone number" do
    assert !Phonelib.valid?('sdffsd')
  end

  test "invalid? with malformed phone number" do
    assert Phonelib.invalid?('sdffsd')
  end

  test "valid? with valid phone number" do
    assert Phonelib.valid? '972541234567'
  end

  test "invalid? with valid phone number" do
    assert !Phonelib.invalid?('972541234567')
  end

  test "possible? with valid phone number" do
    assert Phonelib.possible? '972541234567'
  end

  test "impossible? with valid phone number" do
    assert !Phonelib.impossible?('972541234567')
  end

  test "valid? with invalid phone number" do
    assert !Phonelib.valid?('97254123')
  end

  test "invalid? with invalid phone number" do
    assert Phonelib.invalid?('97254123')
  end

  test "possible? with invalid phone number" do
    assert !Phonelib.possible?('97254123')
  end

  test "impossible? with invalid phone number" do
    assert Phonelib.impossible?('97254123')
  end

  test "possible but not valid phone number" do
    phone = Phonelib.parse('9721234567')
    assert !phone.valid?
    assert phone.possible?
  end

  test "valid_for_country? with correct data" do
    assert Phonelib.valid_for_country?('972541234567', 'IL')
  end
  
  test "valid_for_country? with correct data and national number" do
    assert Phonelib.valid_for_country?('0541234567', 'IL')
  end
  
  test "valid_for_country? with correct data and without prefix" do
    assert Phonelib.valid_for_country?('541234567', 'IL')
  end
  
  test "valid_for_country? with fake data and without prefix" do
    assert !Phonelib.valid_for_country?('541234567', 'US')
  end

  test "invalid_for_country? with correct data" do
    assert !Phonelib.invalid_for_country?('972541234567', 'IL')
  end

  test "invalid_for_country? with incorrect data" do
    assert Phonelib.invalid_for_country?('972541234567', 'US')
  end

  test "valid_for_country? with incorrect data" do
    assert !Phonelib.valid_for_country?('972541234567', 'US')
  end

  test "international method returns with right formatting" do
    phone = Phonelib.parse('972541234567')
    assert phone.international == '+972 54-123-4567'
  end

  test "national method returns right formatting" do
    phone = Phonelib.parse('972541234567')
    assert phone.national == '054-123-4567'
  end

  test "international method returns sanitized when number invalid but possible" do
    phone = Phonelib.parse('9721234567')
    assert phone.international == '+9721234567'
  end

  test "national method returns sanitized national when number invalid but possible" do
    phone = Phonelib.parse('9721234567')
    assert phone.national == '1234567'
  end
end
