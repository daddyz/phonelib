class AddCountryToPhone < ActiveRecord::Migration
  def change
    add_column :phones, :country, :string
  end
end
