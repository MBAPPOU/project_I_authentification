class AddLoginPassword < ActiveRecord::Migration
  def up
    add_column :users,:login,:text
    add_column :users,:password,:text
  end

  def down
    remove_column :users,:login,:text
    remove_column :users,:password,:text
  end
  
end
