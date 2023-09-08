module Fe
  class AnswerSheet < ApplicationRecord
    self.abstract_class = true

=begin
    if Fe.answer_sheet_class == 'Fe::AnswerSheet'
      self.table_name = self.table_name.sub('fe_', Fe.table_name_prefix)
    else
      self.table_name = Fe.answer_sheet_class.constantize.table_name
    end
=end
    include Fe::AnswerSheetConcern
  end
end
