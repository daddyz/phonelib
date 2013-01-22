class AddPossibleNumberToPhone < ActiveRecord::Migration
  def change
    add_column :phones, :possible_number, :string
  end
end
