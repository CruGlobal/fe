require 'rails_helper'

describe Fe::AnswerSheetQuestionSheet do
  it { expect belong_to :answer_sheet }
  it { expect belong_to :question_sheet }
end
