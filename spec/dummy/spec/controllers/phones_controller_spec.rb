require File.expand_path('../../spec_helper.rb',  __FILE__)

describe PhonesController, :type => :controller do

  before(:all) do
    @phone = phones(:valid_and_possible)
    @phone.save
    Phonelib.default_country = nil
  end

  it 'should get index' do
    get :index
    if Rails::VERSION::MAJOR > 5
      expect(response).to have_http_status(:ok)
    else
      expect(response).to be_success
    end
    expect(assigns(:phones)).not_to be_nil
  end

  it 'should get new' do
    get :new
    if Rails::VERSION::MAJOR > 5
      expect(response).to have_http_status(:ok)
    else
      expect(response).to be_success
    end
  end

  it 'should create phone' do
    assert_difference(Phone, :count) do
      if Rails::VERSION::MAJOR > 4
        post :create, params: { phone: { number: @phone.number } }
      else
        post :create, phone: { number: @phone.number }
      end
    end

    expect(response).to redirect_to(phone_path(assigns(:phone)))
  end

  it 'should show phone' do
    if Rails::VERSION::MAJOR > 4
      get :show, params: { id: @phone }
    else
      get :show, id: @phone
    end
    if Rails::VERSION::MAJOR > 5
      expect(response).to have_http_status(:ok)
    else
      expect(response).to be_success
    end
  end

  it 'should get edit' do
    if Rails::VERSION::MAJOR > 4
      get :edit, params: { id: @phone }
    else
      get :edit, id: @phone
    end
    if Rails::VERSION::MAJOR > 5
      expect(response).to have_http_status(:ok)
    else
      expect(response).to be_success
    end
  end

  it 'should update phone' do
    if Rails::VERSION::MAJOR > 4
      put :update, params: { id: @phone, phone: { number: @phone.number } }
    else
      put :update, id: @phone, phone: { number: @phone.number }
    end
    expect(response).to redirect_to(phone_path(assigns(:phone)))
  end

  it 'should destroy phone' do
    assert_difference(Phone, :count, -1) do
      if Rails::VERSION::MAJOR > 4
        delete :destroy, params: { id: @phone }
      else
        delete :destroy, id: @phone
      end
    end

    expect(response).to redirect_to(phones_path)
  end
end
