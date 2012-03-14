class ModifyColumnSecret < ActiveRecord::Migration
  def up
    remove_column :applis,:secret
    add_column :applis,:secret,:integer
  end 
end


