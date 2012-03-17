class AddNameSecret < ActiveRecord::Migration
  def up
    add_column :applis,:name,:string
    add_column :applis,:secret,:integer
  end

  def down
    remove_column :applis,:name,:string
    remove_column :applis,:secret,:integer
  end
  
end
