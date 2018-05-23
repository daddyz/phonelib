class AddCountryNumberToPhone < ActiveRecord::Migration
  def change
    add_column :phones, :country_number, :string
  end
end
