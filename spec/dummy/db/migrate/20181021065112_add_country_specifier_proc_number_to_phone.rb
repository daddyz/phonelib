class AddCountrySpecifierProcNumberToPhone < ActiveRecord::Migration
  def change
    add_column :phones, :country_specifier_proc_number, :string
  end
end
