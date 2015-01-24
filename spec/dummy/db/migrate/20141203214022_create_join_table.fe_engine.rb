# This migration comes from fe_engine (originally 20131003044714)
class CreateJoinTable < ActiveRecord::Migration
  def change
    create_table Fe::AnswerSheetQuestionSheet.table_name do |t|
      t.integer :answer_sheet_id
      t.integer :question_sheet_id
      t.timestamps
    end

    add_index Fe::AnswerSheetQuestionSheet.table_name, [:answer_sheet_id, :question_sheet_id], name: 'answer_sheet_question_sheet'
  end
end
