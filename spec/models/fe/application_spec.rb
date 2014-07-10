require 'rails_helper'

RSpec.describe Fe::Application, :type => :model do
  it { should have_many :answer_sheet_question_sheets }
  it { should have_many :question_sheets }
  it { should have_many :answers }
  it { should have_many :reference_sheets }
end
