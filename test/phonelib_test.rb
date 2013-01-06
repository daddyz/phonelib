require 'test_helper'

class PhonelibTest < ActiveSupport::TestCase
  test "truth" do
    assert_kind_of Module, Phonelib
  end

  test "valid? with valid phone number" do
    assert Phonelib.valid? '972541234567'
  end

  test "possible? with valid phone number" do
    assert Phonelib.valid? '972541234567'
  end

  test "valid? with invalid phone number" do
    assert !Phonelib.valid?('9725412')
  end

  test "possible? with invalid phone number" do
    assert !Phonelib.valid?('9725412')
  end
end
