class Fe::Application < ActiveRecord::Base
  belongs_to :fe_person

  include Fe::AnswerSheetConcern
end
