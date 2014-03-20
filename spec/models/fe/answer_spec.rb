require 'spec_helper'

describe Fe::Answer do
  it { should belong_to :answer_sheet }
  it { should belong_to :question }
  it { should ensure_length_of :short_value }

  it '#to_s' do
    answer = Fe::Answer.new
    answer.value = "abc"
    answer.to_s.should == "abc"
  end
end
