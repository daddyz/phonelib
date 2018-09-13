class AddTypeMobileNumberToPhone < ActiveRecord::Migration
  def change
    add_column :phones, :type_mobile_number, :string
  end
end
