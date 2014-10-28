require 'rails_helper'

describe Fe::Question do
  it { expect have_many :conditions }
  it { expect have_many :dependents }
  it { expect have_many :sheet_answers }
  it { expect belong_to :related_question_sheet }
  
  # it { expect validate_format_of :slug }
  # it { expect validate_length_of :slug }
  # it { expect validate_uniqueness_of :slug }
  
  describe '#default_label?' do 
    it 'expect return true' do 
      question = Fe::Question.new
      #question.default_label?.expect be_true
      expect(question.default_label?).to eq(true)
    end
  end
  
end
