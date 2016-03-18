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
    let(:qs) { create(:question_sheet) }
    let(:ref_qs) { create(:question_sheet) }
    let(:ref_tf) { create(:text_field_element) }
    let(:q) { create(:reference_question, related_question_sheet: ref_qs) }
    let(:applicant) { FactoryGirl.create(:fe_person) }
    let(:application) { FactoryGirl.create(:answer_sheet, applicant_id: applicant.id) }
    let(:r) { create(:reference_sheet, status: 'started', question: q, email_sent_at: 1.hour.ago, applicant_answer_sheet: application) }
    let(:a) { create(:answer, value: 'test', answer_sheet_id: r.id, question: ref_tf) }

    before do
      ref_qs.pages << create(:page)
      ref_qs.pages.first.elements << ref_tf
      @access_key_before = r.access_key
      @a = create(:answer, value: 'test', answer_sheet_id: r.id, question: ref_tf)
      create(:fe_email_template, name: 'Reference Deleted', subject: 'Reference Deleted', content: "<a href='test'>reference deleted</a>")
    end

    it 'should reset the answers and access key if created' do
      r.update_column(:status, 'created')
      r.update_attribute(:email, 'a@b.com')
      expect(r.access_key).to_not eq(@access_key_before)
      expect(Fe::Answer.count).to eq(0)
    end

    it 'should reset the answers and access key if started' do
      r.update_column(:status, 'started')
      r.update_attribute(:email, 'a@b.com')
      expect(r.access_key).to_not eq(@access_key_before)
      expect(Fe::Answer.count).to eq(0)
    end

    it 'should not reset the answers and access key if completed' do
      r.update_column(:status, 'completed')
      r.update_attribute(:email, 'a@b.com')
      expect(r.access_key).to eq(@access_key_before)
      expect(Fe::Answer.count).to eq(1)
    end

    it 'should not reset the answers and access key if completed' do
      r.update_column(:status, 'completed')
      r.update_attribute(:email, 'a@b.com')
      expect(r.access_key).to eq(@access_key_before)
      expect(Fe::Answer.find_by(id: a.id)).to_not be_nil
    end

    it "doesn't delete the answers if allow_quiet_reference_email_changes is set " do
      r.update_column(:status, 'started')
      r.update_attribute(:email, 'a@b.com')
      r.allow_quiet_reference_email_changes = true
      expect(r.access_key).to_not eq(@access_key_before)
      expect(Fe::Answer.count).to eq(0)
    end
  end

  context do
    let(:qs) { create(:question_sheet_with_pages) }
    let(:qs2) { create(:question_sheet_with_pages) }
    let(:p) { qs.pages.first }
    let(:p2) { qs.pages.first }
    let(:ref_el) { create(:reference_element) }
    let(:ref_el2) { create(:reference_element) }
    let(:ref_el3) { create(:reference_element) }
    let(:app) { create(:application) }
    let(:affecting_el) { create(:choice_field_element, label: "Is the reference required?", conditional_type: "Fe::Element", conditional_id: ref_el.id, conditional_answer: "yes") }
    let(:ref_sheet) { create(:reference_sheet, question: ref_el, applicant_answer_sheet_id: app.id) }

    before do
      p.elements << affecting_el << ref_el
      p2.elements << ref_el2
      app.question_sheets << qs << qs2
    end

    context '#computed_visibility_cache_key' do
      it 'returns a cache key that changes when the answers on visibility_affecting_element_ids changes' do
        # make the answer to the conditional question 'no' so that the ref is required (optional false)
        affecting_el.set_response('no', app)
        affecting_el.save_response(app)
        
        cache_key_before = ref_sheet.computed_visibility_cache_key
        
        # make the answer to the conditional question 'yes' so that the ref is required (optional false)
        sleep(1) # make sure the update_at for the answer is changed
        affecting_el.set_response('yes', app)
        affecting_el.save_response(app)
        cache_key_after = ref_sheet.computed_visibility_cache_key

        expect(cache_key_before).to_not eq(cache_key_after)
      end
    end

    context '#update_visible' do
      it "doesn't recompute the visibility if the cache key is the same" do
        # make the answer to the conditional question 'no' so that the ref is required (optional false)
        affecting_el.set_response('no', app)
        affecting_el.save_response(app)
        ref_sheet.update_visible

        # call update_visible again, it shouldn't update anything because the cache
        # key hasn't changed
        allow(ref_sheet).to receive(:question).and_return(ref_el)
        expect(ref_el).to_not receive(:visible?)
        ref_sheet.update_visible
       end
      it 'computes the visibility and sets the cache key if cache key is initially null' do
        ref_sheet.update(visibility_cache_key: nil)

        # make the answer to the conditional question 'no' so that the ref is required (optional false)
        affecting_el.set_response('no', app)
        affecting_el.save_response(app)
        allow(ref_sheet).to receive(:question).and_return(ref_el)
        expect(ref_el).to receive(:visible?).and_return(true)
        ref_sheet.update_visible
        ref_sheet.reload
        expect(ref_sheet.visible).to be true
        expect(ref_sheet.visibility_cache_key).to_not be_nil
      end
      it 'computes the visibility and sets the cache key if the cache key changes' do
        ref_sheet.update(visibility_cache_key: 'something')

        # make the answer to the conditional question 'no' so that the ref is required (optional false)
        affecting_el.set_response('no', app)
        affecting_el.save_response(app)
        allow(ref_sheet).to receive(:question).and_return(ref_el)
        expect(ref_el).to receive(:visible?).and_return(false)
        ref_sheet.update_visible
        ref_sheet.reload
        expect(ref_sheet.visible).to be false
        expect(ref_sheet.visibility_cache_key).to_not eq('something')
      end
    end
  end

  context '#all_affecting_questions_answered' do
    let(:p) { create(:fe_person) }
    let(:a) { create(:answer_sheet, applicant_id: p.id) }
    let(:ref_el) { create(:reference_element) }
    let(:r) { create(:reference_sheet, question_id: ref_el.id, applicant_answer_sheet: a) }
    let(:text_el) { create(:text_field_element) }

    it 'returns true when all visibility affecting questions are answered' do
      expect(r).to receive(:question).and_return(ref_el).twice
      expect(ref_el).to receive(:visibility_affecting_questions).and_return([text_el])
      text_el.set_response('some text response', a)
      text_el.save_response(a)
      expect(r.all_affecting_questions_answered).to be true
    end

    it 'returns false when not all visibility affecting questions are answered' do
      expect(r).to receive(:question).and_return(ref_el).twice
      expect(ref_el).to receive(:visibility_affecting_questions).and_return([text_el])
      expect(r.all_affecting_questions_answered).to be false
    end
  end
end
