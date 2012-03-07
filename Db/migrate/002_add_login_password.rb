class AddLoginPassword < ActiveRecord::Migration
  def up
    add_column :users,:login,:string
    add_column :users,:password,:string
  end

  def down
    remove_column :users,:login,:string
    remove_column :users,:password,:string
  end
  
end
