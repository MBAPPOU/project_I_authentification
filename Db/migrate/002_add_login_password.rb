class AddLoginPassword < ActiveRecord::Migration
  def up
    add_column :users,:login,:text,:null => false
    add_column :users,:password,:text,:null => false
  end

  def down
    remove_column :users,:login,:text,:null => false
    remove_column :users,:password,:text,:null => false
  end
  
end
