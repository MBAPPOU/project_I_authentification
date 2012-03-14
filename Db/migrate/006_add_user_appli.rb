class AddUserAppli < ActiveRecord::Migration
  def up
    add_column :authentifications,:user,:string
    add_column :authentifications,:application,:string
  end

  def down
    add_column :authentifications,:user,:string
    add_column :authentifications,:application,:string
  end
  
end
