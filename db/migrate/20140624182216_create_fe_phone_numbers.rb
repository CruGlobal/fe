class CreateFePhoneNumbers < ActiveRecord::Migration[4.2]
  def change
    create_table Fe::PhoneNumber do |t|
      t.string :number
      t.string :extensions
      t.integer :person_id
      t.string :location
      t.boolean :primary
      t.string :txt_to_email
      t.integer :carrier_id
      t.datetime :email_updated_at

      t.timestamps
    end
  end
end
