class CreateFeUsers < ActiveRecord::Migration
  def change
    create_table :fe_users do |t|
      t.integer :user_id
      t.datetime :last_login
      t.string :type
      t.string :role

      t.timestamps
    end
  end
end
