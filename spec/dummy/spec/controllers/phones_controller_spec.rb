require File.expand_path('../../spec_helper.rb',  __FILE__)

describe PhonesController do

  before(:all) do
    @phone = phones(:valid_and_possible)
    @phone.save
    Phonelib.default_country = nil
  end

  it 'should get index' do
    get :index
    expect(response).to be_success
    expect(assigns(:phones)).not_to be_nil
  end

  it 'should get new' do
    get :new
    expect(response).to be_success
  end

  it 'should create phone' do
    assert_difference(Phone, :count) do
      post :create, phone: { number: @phone.number }
    end

    expect(response).to redirect_to(phone_path(assigns(:phone)))
  end

  it 'should show phone' do
    get :show, id: @phone
    expect(response).to be_success
  end

  it 'should get edit' do
    get :edit, id: @phone
    expect(response).to be_success
  end

  it 'should update phone' do
    put :update, id: @phone, phone: { number: @phone.number }
    expect(response).to redirect_to(phone_path(assigns(:phone)))
  end

  it 'should destroy phone' do
    assert_difference(Phone, :count, -1) do
      delete :destroy, id: @phone
    end

    expect(response).to redirect_to(phones_path)
  end
end
