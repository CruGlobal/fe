require 'spec_helper'

describe Fe::AnswerSheet do
  it { should have_many :answer_sheet_question_sheets }
  it { should have_many :question_sheets }
  it { should have_many :answers }
  it { should have_many :reference_sheets }
end
