require 'spec_helper'

describe Fe::Question do
  it { should have_many :conditions }
  it { should have_many :dependents }
  it { should have_many :sheet_answers }
  it { should belong_to :related_question_sheet }
  
  # it { should validate_format_of :slug }
  # it { should validate_length_of :slug }
  # it { should validate_uniqueness_of :slug }
  
  describe '#default_label?' do 
    it 'should return true' do 
      question = Fe::Question.new
      question.default_label?.should be_true
    end
  end
  
end
