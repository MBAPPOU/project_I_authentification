class AddLoginPassword < ActiveRecord::Migration
  def up
    add_column :users,:login,:password
    add_column :users,:login,:password
  end

  def down
    remove_column :users,:login,:password
    remove_column :users,:login,:password
  end
  
end
