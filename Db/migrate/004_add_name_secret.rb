class AddNameSecret < ActiveRecord::Migration
  def up
    add_column :applis,:name,:string
    add_column :applis,:secret,:integer
  end

  def down
    add_column :applis,:name,:string
    add_column :applis,:secret,:integer
  end
  
end
