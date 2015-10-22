# This migration comes from fe_engine (originally 20151021184250)
class AddQuestionSheetIdInRefs < ActiveRecord::Migration
  def change
    add_column Fe::ReferenceSheet.table_name, :question_sheet_id, :integer
    Fe::ReferenceSheet.reset_column_information

    # set question_sheet_id on all refs
    Fe::ReferenceSheet.joins(:question).update_all("question_sheet_id = related_question_sheet_id")
  end
end
