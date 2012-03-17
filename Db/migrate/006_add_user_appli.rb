class AddUserAppli < ActiveRecord::Migration
  def up
    add_column :authentifications,:user,:user_id
    add_column :authentifications,:application,:appli_id
    add_column :authentifications,:created,:created_at
  end

  def down
    remove_column :authentifications,:user
    remove_column :authentifications,:application
    remove_column :authentifications,:created
  end
  
end
