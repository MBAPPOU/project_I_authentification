class CreateApplis < ActiveRecord::Migration
  def up
    create_table :applis do |t|
    end
  end

  def down
    drop_table :applis
  end
end
