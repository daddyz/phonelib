class PhonesController < ApplicationController
  # GET /phones
  # GET /phones.json
  def index
    @phones = Phone.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @phones }
    end
  end

  # GET /phones/1
  # GET /phones/1.json
  def show
    @phone = Phone.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @phone }
    end
  end

  # GET /phones/new
  # GET /phones/new.json
  def new
    @phone = Phone.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @phone }
    end
  end

  # GET /phones/1/edit
  def edit
    @phone = Phone.find(params[:id])
  end

  # POST /phones
  # POST /phones.json
  def create
    @phone = Phone.new(params[:phone])

    respond_to do |format|
      if @phone.save
        format.html { redirect_to @phone, notice: 'Phone was successfully created.' }
        format.json { render json: @phone, status: :created, location: @phone }
      else
        format.html { render action: "new" }
        format.json { render json: @phone.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /phones/1
  # PUT /phones/1.json
  def update
    @phone = Phone.find(params[:id])

    respond_to do |format|
      if @phone.update_attributes(params[:phone])
        format.html { redirect_to @phone, notice: 'Phone was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @phone.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /phones/1
  # DELETE /phones/1.json
  def destroy
    @phone = Phone.find(params[:id])
    @phone.destroy

    respond_to do |format|
      format.html { redirect_to phones_url }
      format.json { head :no_content }
    end
  end
end
