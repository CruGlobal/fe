require 'rails_helper'

describe Fe::Answer do
  it { expect belong_to :answer_sheet }
  it { expect belong_to :question }
  it { expect validate_length_of :short_value }

  it '#to_s' do
    answer = Fe::Answer.new
    answer.value = "abc"
    expect(answer.to_s).to eq("abc")
  end
end
