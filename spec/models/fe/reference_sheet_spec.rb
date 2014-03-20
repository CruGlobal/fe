require 'spec_helper'

describe Fe::ReferenceSheet do
  it { should belong_to :question }  
  it { should belong_to :applicant_answer_sheet }
  # it { should validate_presence_of :first_name } # need to add started_at column
  # it { should validate_presence_of :last_name } # need to add started_at column
  # it { should validate_presence_of :phone } # need to add started_at column
  # it { should validate_presence_of :email } # need to add started_at column
  # it { should validate_presence_of :relationship } # need to add started_at column
end
