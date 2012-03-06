class AddNameSecret < ActiveRecord::Migration
  def up
    add_column :applis,:name,:text,:null => false
    add_column :applis,:secret,:text,:null => false
  end

  def down
    add_column :applis,:name,:text,:null => false
    add_column :applis,:secret,:text,:null => false
  end
  
end
