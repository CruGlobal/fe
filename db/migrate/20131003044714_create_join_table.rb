class CreateJoinTable < ActiveRecord::Migration
  def change
    create_table AnswerSheetQuestionSheet.table_name do |t|
      t.integer :answer_sheet_id
      t.integer :question_sheet_id
      t.timestamps
    end
  end
end
