class AnswerSheetQuestionSheet < ActiveRecord::Base
  set_table_name "#{Qe.table_name_prefix}#{self.table_name}"
  belongs_to :answer_sheet
  belongs_to :question_sheet
end
