class AddStrictFieldToPhone < ActiveRecord::Migration
  def change
    add_column :phones, :strict_number, :string
  end
end
