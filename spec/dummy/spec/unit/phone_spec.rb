require File.expand_path('../../spec_helper.rb',  __FILE__)

describe Phone do
  it 'saves with valid phone' do
    phone = Phone.new(number: '972541234567')

    expect(phone.save).to be true
    expect(phone.errors.empty?).to be true
  end

  it "can't save with invalid phone" do
    phone = Phone.new(number: 'wrong')

    expect(phone.save).to be false
    expect(phone.errors.any?).to be true
  end

  it "is invalid when phone is invalid and country is specified" do
    phone = Phone.new(number: '1305558858', country: 'us')

    expect(phone.valid?).to be false
    expect(phone.errors.any?).to be true
  end

  it "is valid when phone is valid and country is specified" do
    phone = Phone.new(number: '3175082248', country: 'us')

    expect(phone.valid?).to be true
    expect(phone.errors.any?).to be false
  end

  it 'passes when valid' do
    phone = phones(:valid_and_possible)
    expect(phone.save).to be true
    expect(phone.errors.empty?).to be true
  end

  it 'fails with wrong' do
    phone = phones(:wrong)
    expect(phone.save).to be false
    expect(phone.errors.any?).to be true
  end

  it 'passes with allow blank' do
    phone = phones(:only_valid)
    expect(phone.save).to be true
    expect(phone.errors.empty?).to be true
  end

  it 'fails without allow blank' do
    phone = phones(:only_possible)
    expect(phone.save).to be false
    expect(phone.errors.any?).to be true
  end

  it 'fails when wrong possible and not blank' do
    phone = phones(:valid_with_bad_possible)
    expect(phone.save).to be false
    expect(phone.errors.any?).to be true
  end

  it 'should pass with valid type' do
    phone = phones(:valid_type)
    expect(phone.save).to be true
    expect(phone.errors.empty?).to be true
  end

  it 'should fail with invalid type' do
    phone = phones(:invalid_type)
    expect(phone.save).to be false
    expect(phone.errors.any?).to be true
  end

  it 'should pass with possible type' do
    phone = phones(:possible_type)
    expect(phone.save).to be true
    expect(phone.errors.empty?).to be true
  end

  it 'should fail with impossible type' do
    phone = phones(:impossible_type)
    expect(phone.save).to be false
    expect(phone.errors.any?).to be true
  end

  it 'should raise ActiveModel::StrictValidationFailed on strict fields' do
    if Rails::VERSION::STRING >= '3.2'
      phone = phones(:invalid_strict)
      expect{phone.valid?}.to raise_error(ActiveModel::StrictValidationFailed)
    else
      # this test is suitable for rails >= 3.2 only
    end
  end

end
