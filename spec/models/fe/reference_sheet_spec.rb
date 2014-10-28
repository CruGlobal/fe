require 'rails_helper'

describe Fe::ReferenceSheet do
  it { expect belong_to :question }  
  it { expect belong_to :applicant_answer_sheet }
  # it { expect validate_presence_of :first_name } # need to add started_at column
  # it { expect validate_presence_of :last_name } # need to add started_at column
  # it { expect validate_presence_of :phone } # need to add started_at column
  # it { expect validate_presence_of :email } # need to add started_at column
  # it { expect validate_presence_of :relationship } # need to add started_at column
end
