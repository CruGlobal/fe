require 'rails_helper'

describe Fe::QuestionSet do
  let(:app) { create(:application) }
  let(:app2) { create(:application) }

  before do
    @page = create(:page)
    @el_confidential = create(:text_field_element, label: 'conf1', is_confidential: true, share: true)
    @el_visible = create(:text_field_element, label: 'vis1', is_confidential: false, share: false)
    @el_confidential2 = create(:text_field_element, label: 'conf2', is_confidential: true, share: true)
    @el_visible2 = create(:text_field_element, label: 'vis2', is_confidential: false, share: true)
    @page.elements << @el_confidential << @el_visible << @el_confidential2 << @el_visible2
    @question_set = Fe::QuestionSet.new(@page.elements, app)
  end

  it 'should filter default show' do
    # filter out confidential questions and questions with share flag (the share flag would likely
    # never be used to filter, but just to test that it will only filter those that match all the
    # filter methods)
    @question_set.set_filter(filter_default: :show, filter: [ :is_confidential, :share ])
    expect(@question_set.elements).to eq([@el_visible, @el_visible2])
  end

  it 'should filter default hide' do
    # show only confidential questions and questions with share flag (the share flag would likely
    # never be used to filter, but just to test that it will only filter those that match all the
    # filter methods)
    @question_set.set_filter(filter_default: :hide, filter: [ :is_confidential, :share ])
    expect(@question_set.elements).to eq([@el_confidential, @el_confidential2])
  end

  context 'saving answers (#post then #save)' do
    it 'saves a new value' do
      @question_set.post({ @el_visible.id => 'a text response' }, app)
      @question_set.save
      expect(Fe::Answer.count).to eq(1)
      expect(Fe::Answer.first.value).to eq('a text response')
      expect(Fe::Answer.first.answer_sheet_id).to eq(app.id)
      expect(Fe::Answer.first.question_id).to eq(@el_visible.id)
    end
    it 'replaces an existing answer' do
      create(:answer, value: 'a text response', answer_sheet: app, question: @el_visible)
      @question_set = Fe::QuestionSet.new(@page.elements, app) # need this to reload the elements in the question set to get the new answer
      @question_set.post({ @el_visible.id => 'an updated response' }, app)
      @question_set.save
      expect(Fe::Answer.count).to eq(1)
      expect(Fe::Answer.first.value).to eq('an updated response')
      expect(Fe::Answer.first.answer_sheet_id).to eq(app.id)
      expect(Fe::Answer.first.question_id).to eq(@el_visible.id)
    end
    it "doesn't save empty strings continually" do
      create(:answer, value: '', answer_sheet: app, question: @el_visible)
      @question_set = Fe::QuestionSet.new(@page.elements, app) # need this to reload the elements in the question set to get the new answer
      @question_set.post({ @el_visible.id => '' }, app)
      @question_set.save
      expect(Fe::Answer.count).to eq(1)
      expect(Fe::Answer.first.value).to eq('')
      expect(Fe::Answer.first.answer_sheet_id).to eq(app.id)
      expect(Fe::Answer.first.question_id).to eq(@el_visible.id)
    end
    it 'saves multiple values' do
      @el_visible.update(kind: 'Fe::ChoiceField', style: 'checkbox', content: "choice 1\nchoice 2")
      create(:answer, value: 'choice 1', answer_sheet: app, question: @el_visible)
      @question_set = Fe::QuestionSet.new(@page.elements, app) # need this to reload the elements in the question set to get the new answer
      @question_set.post({ @el_visible.id => { '0' => 'choice 1', '1' => 'choice 2' } }, app)
      @question_set.save
      expect(Fe::Answer.count).to eq(2)
      expect(Fe::Answer.first.value).to eq('choice 1')
      expect(Fe::Answer.first.answer_sheet_id).to eq(app.id)
      expect(Fe::Answer.first.question_id).to eq(@el_visible.id)
      expect(Fe::Answer.second.value).to eq('choice 2')
      expect(Fe::Answer.second.answer_sheet_id).to eq(app.id)
      expect(Fe::Answer.second.question_id).to eq(@el_visible.id)
    end
    it 'saves the same value for different answer sheets' do
      @el_visible.update(kind: 'Fe::ChoiceField', style: 'checkbox', content: "choice 1\nchoice 2")
      @question_set = Fe::QuestionSet.new(@page.elements, app) # need this to reload the elements in the question set to get the new answer
      @question_set.post({ @el_visible.id => { '0' => 'choice 1' } }, app)
      @question_set.save
      @question_set = Fe::QuestionSet.new(@page.elements, app2) # need this to save answers to app2
      $b = true
      @question_set.post({ @el_visible.id => { '0' => 'choice 1' } }, app2)
      @question_set.save
      $b = false
      expect(Fe::Answer.count).to eq(2)
      expect(Fe::Answer.first.value).to eq('choice 1')
      expect(Fe::Answer.first.answer_sheet_id).to eq(app.id)
      expect(Fe::Answer.first.question_id).to eq(@el_visible.id)
      expect(Fe::Answer.second.value).to eq('choice 1')
      expect(Fe::Answer.second.answer_sheet_id).to eq(app2.id)
      expect(Fe::Answer.second.question_id).to eq(@el_visible.id)
    end
  end

  context '#update_reference_sheet_visibility' do
    let(:qs) { create(:question_sheet_with_pages) }
    let(:qs2) { create(:question_sheet_with_pages) }
    let(:p) { qs.pages.first }
    let(:p2) { qs.pages.first }
    let(:ref_el) { create(:reference_element) }
    let(:ref_el2) { create(:reference_element) }
    let(:ref_el3) { create(:reference_element) }
    let(:app) { create(:application) }
    let(:affecting_el) { create(:text_field_element) }

    before do
      p.elements << ref_el
      p2.elements << ref_el2
      app.question_sheets << qs << qs2
    end

    it "calls update_visible for all refs whose visibility_affecting_element_ids include the answer's question" do
      expect(app).to receive(:question_sheets_all_reference_elements).and_return([ref_el, ref_el2])
      expect(ref_el).to receive(:visibility_affecting_element_ids).and_return([affecting_el.id])
      expect(ref_el).to receive(:update_visible)
      ref_el_arr = [ref_el]
      allow(app).to receive(:all_references).and_return(ref_el_arr)
      allow(ref_el_arr).to receive(:where).with(question_id: ref_el.id).and_return(ref_el_arr)
      expect(ref_el2).to receive(:visibility_affecting_element_ids).and_return([])
      qs = Fe::QuestionSet.new([affecting_el], app)
      qs.update_reference_sheet_visibility
    end
  end
end
