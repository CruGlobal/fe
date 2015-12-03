require 'rails_helper'

describe Fe::AnswerPagesController, type: :controller do
  context '#edit' do
    let(:answer_sheet) { create(:answer_sheet) }
    let(:page) { create(:page) }

    it 'should work' do
      question_sheet = page.question_sheet
      create(:answer_sheet_question_sheet, answer_sheet: answer_sheet, question_sheet: question_sheet)
      get :edit, id: page.id, answer_sheet_id: answer_sheet.id
      expect(response).to render_template('fe/answer_pages/_answer_page')
    end
    context 'filtering' do
      let(:el_confidential) { create(:text_field_element, is_confidential: true) }
      let(:el_visible) { create(:text_field_element, is_confidential: false) }
      let(:el_visible2) { create(:text_field_element, is_confidential: false) }

      before do
        page.elements << el_confidential << el_visible << el_visible2
        question_sheet = page.question_sheet
        create(:answer_sheet_question_sheet, answer_sheet: answer_sheet, question_sheet: question_sheet)
      end

      it 'should filter out elements' do
        allow_any_instance_of(Fe::AnswerPagesController).to receive(:get_filter).and_return(filter_default: :show, filter: [ :is_confidential ])
        get :edit, id: page.id, answer_sheet_id: answer_sheet.id
        expect(assigns(:elements)).to_not include(el_confidential)
        expect(assigns(:elements)).to include(el_visible)
        expect(assigns(:elements)).to include(el_visible2)
      end
      it 'should filter in elements' do
        allow_any_instance_of(Fe::AnswerPagesController).to receive(:get_filter).and_return(filter_default: :hide, filter: [ :is_confidential ])
        get :edit, id: page.id, answer_sheet_id: answer_sheet.id
        expect(assigns(:elements)).to include(el_confidential)
        expect(assigns(:elements)).to_not include(el_visible)
        expect(assigns(:elements)).to_not include(el_visible2)
      end
    end
  end

  context '#update' do
    it 'should work' do
      answer_sheet = create(:answer_sheet)
      page = create(:page)
      question_sheet = page.question_sheet
      create(:answer_sheet_question_sheet, answer_sheet: answer_sheet, question_sheet: question_sheet)
      element = create(:text_field_element)
      create(:page_element, element: element, page: page)
      # ref
      reference_question = create(:reference_question)
      reference_sheet = create(:reference_sheet, applicant_answer_sheet_id: answer_sheet.id, email: 'initial@ref.com')

      xhr :put, :update, {
        answers: { "#{element.id}" => 'answer here' },
        reference: { "#{reference_sheet.id}" => {
          relationship: 'roommate',
          title: 'A',
          first_name: 'FN',
          last_name: 'LN',
          phone: 'phone',
          email: 'email@reference.com'
        } },
        id: page.id,
        answer_sheet_id: answer_sheet.id
      }

      expect(response).to render_template('fe/answer_pages/update')
      expect(Fe::Answer.find_by(answer_sheet_id: answer_sheet.id, question_id: element.id).value).to eq('answer here')
      expect(reference_sheet.reload.email).to eq('email@reference.com')
    end
    it 'should store a reference sheet answer' do
      # create a normal applicant sheet to make sure the answer isn't saved to that
      answer_sheet = create(:answer_sheet)
      page = create(:page)
      question_sheet = page.question_sheet
      create(:answer_sheet_question_sheet, answer_sheet: answer_sheet, question_sheet: question_sheet)
      element = create(:text_field_element)
      create(:page_element, element: element, page: page)
      # ref
      ref_page = create(:page, label: 'Ref Page')
      ref_question_sheet = ref_page.question_sheet
      ref_element = create(:text_field_element)
      create(:page_element, element: ref_element, page: ref_page)
      reference_question = create(:reference_question, related_question_sheet_id: ref_question_sheet.id)
      reference_sheet = create(:reference_sheet, question_id: reference_question.id, applicant_answer_sheet_id: answer_sheet.id, email: 'initial@ref.com')

      xhr :put, :update, {
        answers: { "#{ref_element.id}" => 'ref answer here' },
        id: ref_page.id,
        answer_sheet_id: reference_sheet.id,
        answer_sheet_type: 'Fe::ReferenceSheet'
      }

      expect(response).to render_template('fe/answer_pages/update')
      expect(Fe::Answer.find_by(answer_sheet_id: reference_sheet.id, question_id: ref_element.id).value).to eq('ref answer here')
      expect(Fe::Answer.find_by(answer_sheet_id: answer_sheet.id, question_id: element.id)).to be_nil
      # check the associations on reference/answer sheet returns the correct answers
      expect(reference_sheet.reload.answers.collect(&:value)).to eq(['ref answer here'])
      expect(answer_sheet.reload.answers).to eq([])
    end
  end

end
