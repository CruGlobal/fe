class CreateFeApplications < ActiveRecord::Migration
  def change
    create_table :fe_applications do |t|
      t.integer :person_id
      t.integer :fe_apply_id

      t.timestamps
    end
  end
end
