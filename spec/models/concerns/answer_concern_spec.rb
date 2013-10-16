require 'spec_helper'

describe Answer do 
  it { should belong_to :answer_sheet }
  it { should belong_to :question }
  
  it '#to_s' do 
    answer = Answer.new
    answer.value = "abc"
    answer.to_s.should == "abc"
  end
end
