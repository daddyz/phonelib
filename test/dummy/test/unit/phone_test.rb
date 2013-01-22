require 'test_helper'

class PhoneTest < ActiveSupport::TestCase
  test "saves with valid phone" do
    phone = Phone.new(number: '972541234567')

    assert phone.save
    assert phone.errors.empty?
  end

  test "can't save with invalid phone" do
    phone = Phone.new(number: 'wrong')

    assert !phone.save
    assert phone.errors.any?
  end

  test "valid passes" do
    phone = phones(:valid_and_possible)
    assert phone.save
    assert phone.errors.empty?
  end

  test "wrong fails" do
    phone = phones(:wrong)
    assert !phone.save
    assert phone.errors.any?
  end

  test "allow blank passes" do
    phone = phones(:only_valid)
    assert phone.save
    assert phone.errors.empty?
  end

  test "without allow blank fails" do
    phone = phones(:only_possible)
    assert !phone.save
    assert phone.errors.any?
  end

  test "wrong possible and not blank fails" do
    phone = phones(:valid_with_bad_possible)
    assert !phone.save
    assert phone.errors.any?
  end
end
