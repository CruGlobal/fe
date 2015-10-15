# This migration comes from fe_engine (originally 20131003044250)
class CreateReferenceSheets < ActiveRecord::Migration
  def change
    create_table Fe::ReferenceSheet.table_name do |t|
      t.integer  :question_id
      t.integer  :applicant_answer_sheet_id
      t.datetime :email_sent_at
      t.string   :relationship
      t.string   :title
      t.string   :first_name
      t.string   :last_name
      t.string   :phone
      t.string   :email
      t.string   :status
      t.datetime :submitted_at
      t.datetime :started_at
      t.string   :access_key
      t.timestamps
    end
    
    add_column Fe::Element.table_name, :related_question_sheet_id, :integer
    add_index Fe::ReferenceSheet.table_name, :question_id
    add_index Fe::ReferenceSheet.table_name, :applicant_answer_sheet_id
  end
end
