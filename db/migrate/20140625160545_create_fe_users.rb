class CreateFeUsers < ActiveRecord::Migration[4.2]
  def change
    create_table Fe::User do |t|
      t.integer :user_id
      t.datetime :last_login
      t.string :type
      t.string :role

      t.timestamps
    end
  end
end
