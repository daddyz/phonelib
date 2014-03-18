class AddMoreFieldsToPhone < ActiveRecord::Migration
  def change
    add_column :phones, :type_number, :string
    add_column :phones, :possible_type_number, :string
  end
end
