require 'rails_helper'

describe Fe::Condition, type: :model do
  it { expect belong_to :question_sheet }
  it { expect belong_to :trigger }
  it { expect validate_presence_of :expression }
  it { expect validate_length_of :expression }
end
