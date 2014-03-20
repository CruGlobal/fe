require 'spec_helper'

describe Fe::AnswerSheetQuestionSheet do
  it { should belong_to :answer_sheet }
  it { should belong_to :question_sheet }
end
