# This migration comes from fe_engine (originally 20151021184250)
class AddQuestionSheetIdInRefs < ActiveRecord::Migration
  def change
    add_column Fe::ReferenceSheet.table_name, :question_sheet_id, :integer

    # set initial question_sheet_id on all refs
    # NOTE: doing an update on a join query is a pain to do in both mysql and postgres
    # and since there's not that many reference questions, this should be fine
    Fe::ReferenceQuestion.all.each do |rq|
      Fe::ReferenceSheet.where(question_id: rq.id).update_all(question_sheet_id: rq.related_question_sheet_id)
    end
  end
end
