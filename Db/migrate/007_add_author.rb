class AddAuthor < ActiveRecord::Migration
  def up
    add_column :applis,:author,:string
  end

  def down
    remove_column :applis,:author
  end
  
end
