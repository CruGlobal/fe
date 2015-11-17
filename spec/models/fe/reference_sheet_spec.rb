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

  it 'returns the user for applicant' do
    p = create(:fe_person)
    a = create(:answer_sheet, applicant_id: p.id)
    r = create(:reference_sheet, applicant_answer_sheet: a)
    expect(r.applicant).to eq(a.applicant)
  end 

  context '#required?' do
    it 'should return the opposite of required? when optional? is false' do
      question_sheet = FactoryGirl.create(:question_sheet_with_pages)
      application = FactoryGirl.create(:answer_sheet)
      application.question_sheets << question_sheet
      element = FactoryGirl.create(:reference_element, label: "Reference question here", required: true)
      reference = FactoryGirl.create(:reference_sheet, applicant_answer_sheet: application, question: element)
      allow(reference).to receive(:optional?).and_return(false)
      expect(reference.optional?).to be false
      expect(reference.required?).to be true
    end
    it 'should return the opposite of required? when optional? is true' do
      question_sheet = FactoryGirl.create(:question_sheet_with_pages)
      application = FactoryGirl.create(:answer_sheet)
      application.question_sheets << question_sheet
      element = FactoryGirl.create(:reference_element, label: "Reference question here", required: true)
      reference = FactoryGirl.create(:reference_sheet, applicant_answer_sheet: application, question: element)
      allow(reference).to receive(:optional?).and_return(true)
      expect(reference.optional?).to be true
      expect(reference.required?).to be false
    end
  end

  context '#optional?' do
    it 'returns true when the ref question element is hidden from a yes/no choice_field' do
      question_sheet = FactoryGirl.create(:question_sheet_with_pages)
      choice_field = FactoryGirl.create(:choice_field_element, label: "Is the reference required?")
      question_sheet.pages.reload
      question_sheet.pages[3].elements << choice_field
      element = FactoryGirl.create(:reference_element, label: "Reference question here", choice_field_id: choice_field.id, required: true)
      question_sheet.pages[3].elements << element

      application = FactoryGirl.create(:answer_sheet)
      application.question_sheets << question_sheet
      reference = FactoryGirl.create(:reference_sheet, applicant_answer_sheet: application, question: element)

      # make the answer to the conditional question 'no' so that the ref is not required (optional true)
      choice_field.set_response("no", application)
      choice_field.save_response(application)

      expect(reference.optional?).to be true
    end
    it 'returns false when the ref question element is visible from a yes/no choice_field' do
      question_sheet = FactoryGirl.create(:question_sheet_with_pages)
      choice_field = FactoryGirl.create(:choice_field_element, label: "Is the reference required?")
      question_sheet.pages.reload
      question_sheet.pages[3].elements << choice_field
      element = FactoryGirl.create(:reference_element, label: "Reference question here", choice_field_id: choice_field.id, required: true)
      question_sheet.pages[3].elements << element

      question_sheet.pages[3].elements << choice_field
      application = FactoryGirl.create(:answer_sheet)
      application.question_sheets << question_sheet
      reference = FactoryGirl.create(:reference_sheet, applicant_answer_sheet: application, question: element)

      # make the answer to the conditional question 'yes' so that the ref is required (optional false)
      choice_field.set_response("yes", application)
      choice_field.save_response(application)

      expect(reference.optional?).to be false
    end
    it 'returns false when the ref question element is hidden from a conditional element' do
      question_sheet = FactoryGirl.create(:question_sheet_with_pages)
      choice_field = FactoryGirl.create(:choice_field_element, label: "Is the reference required?", conditional_type: "Fe::Element", conditional_answer: "yes")
      question_sheet.pages.reload
      question_sheet.pages[3].elements << choice_field
      element = FactoryGirl.create(:reference_element, label: "Reference question here", required: true)
      question_sheet.pages[3].elements << element

      application = FactoryGirl.create(:answer_sheet)
      application.question_sheets << question_sheet
      reference = FactoryGirl.create(:reference_sheet, applicant_answer_sheet: application, question: element)

      # make the answer to the conditional question 'no' so that the ref is not required (optional true)
      choice_field.set_response("no", application)
      choice_field.save_response(application)

      expect(reference.optional?).to be true
    end
    it 'returns false when the ref question element is visible from a conditional element' do
      question_sheet = FactoryGirl.create(:question_sheet_with_pages)
      choice_field = FactoryGirl.create(:choice_field_element, label: "Is the reference required?", conditional_type: "Fe::Element", conditional_answer: "yes")
      question_sheet.pages.reload
      question_sheet.pages[3].elements << choice_field
      element = FactoryGirl.create(:reference_element, label: "Reference question here", required: true)
      question_sheet.pages[3].elements << element

      application = FactoryGirl.create(:answer_sheet)
      application.question_sheets << question_sheet
      reference = FactoryGirl.create(:reference_sheet, applicant_answer_sheet: application, question: element)

      # make the answer to the conditional question 'yes' so that the ref is required (optional false)
      choice_field.set_response("yes", application)
      choice_field.save_response(application)

      expect(reference.optional?).to be false
    end
  end

  it 'sets the question_sheet_id' do
    element = FactoryGirl.create(:reference_element, label: "Reference question here", required: true, related_question_sheet_id: 1)
    application = FactoryGirl.create(:answer_sheet)
    reference = FactoryGirl.create(:reference_sheet, applicant_answer_sheet: application, question: element)
    expect(reference.question_sheet_id).to eq(1)
  end

  it 'starts out in created status' do
    r = create(:reference_sheet)
    expect(r.status).to eq('created')
  end

  context '#check_email_change' do
    before do
      qs = create(:question_sheet)
      ref_qs = create(:question_sheet)
      ref_qs.pages << create(:page)
      ref_tf = create(:text_field_element)
      ref_qs.pages.first.elements << ref_tf
      q = create(:reference_question, related_question_sheet: ref_qs)
      @r = create(:reference_sheet, status: 'started', question: q)
      @access_key_before = @r.access_key
      @a = create(:answer, value: 'test', answer_sheet_id: @r.id, question: ref_tf)
    end

    it 'should reset the answers and access key if created' do
      @r.update_column(:status, 'created')
      @r.update_attribute(:email, 'a@b.com')
      expect(@r.access_key).to_not eq(@access_key_before)
      expect(Fe::Answer.find_by(id: @a.id)).to be_nil
    end

    it 'should reset the answers and access key if started' do
      @r.update_column(:status, 'started')
      @r.update_attribute(:email, 'a@b.com')
      expect(@r.access_key).to_not eq(@access_key_before)
      expect(Fe::Answer.find_by(id: @a.id)).to be_nil
    end

    it 'should not reset the answers and access key if completed' do
      @r.update_column(:status, 'completed')
      @r.update_attribute(:email, 'a@b.com')
      expect(@r.access_key).to eq(@access_key_before)
      expect(Fe::Answer.find_by(id: @a.id)).to_not be_nil
    end
  end
end
