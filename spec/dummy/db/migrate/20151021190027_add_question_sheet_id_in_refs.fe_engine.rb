# This migration comes from fe_engine (originally 20151021184250)
class AddQuestionSheetIdInRefs < ActiveRecord::Migration
  def change
    add_column Fe::ReferenceSheet.table_name, :question_sheet_id, :integer

    # set initial question_sheet_id on all refs
    Fe::ReferenceSheet.joins(:question).update_all("#{Fe::ReferenceSheet.table_name}.question_sheet_id = #{Fe::ReferenceQuestion.table_name}.related_question_sheet_id")
  end
end
