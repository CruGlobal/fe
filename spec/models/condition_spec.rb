require 'spec_helper'

describe Condition do 
  it { should belong_to :question_sheet }
  it { should belong_to :trigger }
  it { should validate_presence_of :expression }
  it { should ensure_length_of :expression }
end
