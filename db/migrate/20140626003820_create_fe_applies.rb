class CreateFeApplies < ActiveRecord::Migration
  def change
    create_table :fe_applies do |t|
      t.integer :applicant_id
      t.string :status
      t.datetime :submitted_at

      t.timestamps
    end
  end
end
