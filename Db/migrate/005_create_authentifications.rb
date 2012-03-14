class CreateAuthentifications < ActiveRecord::Migration
  def up
    create_table :authentifications do |t|
    end
  end

  def down
    drop_table :authentifications
  end
end
