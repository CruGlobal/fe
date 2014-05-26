module Fe
  class AnswerSheet < ActiveRecord::Base
    if Fe.answer_sheet_class.constantize == 'Fe::AnswerSheet'
      self.table_name = self.table_name.sub('fe_', Fe.table_name_prefix)
    else
      self.table_name = Fe.answer_sheet_class.constantize.table_name
    end
    include Fe::AnswerSheetConcern
  end
end
