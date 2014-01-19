require File.expand_path('../../spec_helper.rb',  __FILE__)

describe Phone do
  it 'saves with valid phone' do
    phone = Phone.new(number: '972541234567')

    assert phone.save
    assert phone.errors.empty?
  end

  it "can't save with invalid phone" do
    phone = Phone.new(number: 'wrong')

    assert !phone.save
    assert phone.errors.any?
  end

  it 'valid passes' do
    phone = phones(:valid_and_possible)
    assert phone.save
    assert phone.errors.empty?
  end

  it 'wrong fails' do
    phone = phones(:wrong)
    assert !phone.save
    assert phone.errors.any?
  end

  it 'allow blank passes' do
    phone = phones(:only_valid)
    assert phone.save
    assert phone.errors.empty?
  end

  it 'without allow blank fails' do
    phone = phones(:only_possible)
    assert !phone.save
    assert phone.errors.any?
  end

  it 'wrong possible and not blank fails' do
    phone = phones(:valid_with_bad_possible)
    assert !phone.save
    assert phone.errors.any?
  end
end
