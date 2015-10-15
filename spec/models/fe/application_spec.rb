require 'rails_helper'

RSpec.describe Fe::Application, :type => :model do
  it { expect have_many :answer_sheet_question_sheets }
  it { expect have_many :question_sheets }
  it { expect have_many :answers }
  it { expect have_many :reference_sheets }
end
