# This migration comes from fe_engine (originally 20140624180246)
class CreateFeAddresses < ActiveRecord::Migration
  def change
    create_table :fe_addresses do |t|
      t.datetime :startdate
      t.datetime :enddate
      t.string :address1
      t.string :address2
      t.string :address3
      t.string :address4
      t.string :address_type
      t.string :city
      t.string :state
      t.string :zip
      t.string :country
      t.integer :person_id

      t.timestamps
    end
  end
end
