class CreateFePeople < ActiveRecord::Migration[4.2]
  def change
    create_table Fe::Person.table_name do |t|
      t.string :first_name
      t.string :last_name
      t.integer :user_id
      t.boolean :is_staff

      t.timestamps
    end
  end
end
