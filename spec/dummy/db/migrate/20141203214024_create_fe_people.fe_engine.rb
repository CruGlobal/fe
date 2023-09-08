# This migration comes from fe_engine (originally 20140623153424)
class CreateFePeople < ActiveRecord::Migration[4.2]
  def change
    create_table :fe_people do |t|
      t.string :first_name, limit: 50
      t.string :last_name, limit: 50
      t.integer :user_id
      t.boolean :is_staff

      t.timestamps
    end
  end
end
