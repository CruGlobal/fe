require 'rails_helper'

describe Fe::ReferenceSheet do
  it { expect belong_to :question }  
  it { expect belong_to :applicant_answer_sheet }
  # it { expect validate_presence_of :first_name } # need to add started_at column
  # it { expect validate_presence_of :last_name } # need to add started_at column
  # it { expect validate_presence_of :phone } # need to add started_at column
  # it { expect validate_presence_of :email } # need to add started_at column
  # it { expect validate_presence_of :relationship } # need to add started_at column
  
  context '#access_key' do
    it 'should generate two different in the same second' do
      # there's a small chance the first and second access keys generated will be in different seconds
      # doing it 5 times should make it extremely to pass despite there being a bug
      5.times do
        r = Fe::ReferenceSheet.new email: 'tester@test.com'
        k1 = r.generate_access_key
        k2 = r.generate_access_key
        expect(k1).to_not eq(k2)
      end
    end
  end

  it 'returns the user for applicant' do
    p = create(:fe_person)
    a = create(:answer_sheet, applicant_id: p.id)
    r = create(:reference_sheet, applicant_answer_sheet: a)
    expect(r.applicant).to eq(a.applicant)
  end 
end
