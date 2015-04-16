require 'rails_helper'

describe Fe::AnswerSheetsController, type: :controller do
  let(:question_sheet) { create(:question_sheet) }
  let(:answer_sheet) { create(:answer_sheet, applicant_id: create(:fe_person).id) }

  context '#index' do
    it 'should work' do
      create(:answer_sheet_question_sheet, question_sheet: question_sheet, answer_sheet: answer_sheet)

      get :index
      expect(assigns(:answer_sheets).to_a).to eq([answer_sheet])
    end
  end
  context '#create' do
    it 'should work' do
      create(:answer_sheet_question_sheet, question_sheet: question_sheet, answer_sheet: answer_sheet)

      post :create, question_sheet_id: question_sheet.id
      expect(assigns(:answer_sheet)).to_not be_nil
    end
  end
  context '#edit' do
    it 'should work' do
      create(:answer_sheet_question_sheet, question_sheet: question_sheet, answer_sheet: answer_sheet)
      page = create(:page, question_sheet: question_sheet)

      get :edit, id: answer_sheet.id
      expect(assigns(:elements)).to eq([])
      expect(assigns(:page)).to eq(page)
    end
    context 'when the question_sheet is blank' do
      context 'when referrer is available' do
        it 'should redirect to referrer' do
          create(:answer_sheet_question_sheet, question_sheet: question_sheet, answer_sheet: answer_sheet)
          request.env['HTTP_REFERER'] = '/referrer'

          get :edit, id: answer_sheet.id
          expect(response).to redirect_to('http://test.host/referrer')
        end
      end
      context 'when referrer is not available' do
        it 'should render an empty page with a flash message' do
          create(:answer_sheet_question_sheet, question_sheet: question_sheet, answer_sheet: answer_sheet)

          get :edit, id: answer_sheet.id
          expect(response.body['Sorry, there are no questions for this form yet.']).to_not be_nil
        end
      end
    end
  end
  context '#show' do
    it 'should work' do
      create(:answer_sheet_question_sheet, question_sheet: question_sheet, answer_sheet: answer_sheet)
      page = create(:page, question_sheet: question_sheet)
      text_field = create(:text_field_element)
      create(:page_element, element: text_field, page: page)

      get :show, id: answer_sheet.id
      expect(assigns(:elements)).to eq(page => [text_field])
    end
  end
  context '#send_reference_invite' do
    it 'should work' do
      create(:answer_sheet_question_sheet, question_sheet: question_sheet, answer_sheet: answer_sheet)
      page = create(:page, question_sheet: question_sheet)
      ref_question = create(:reference_element)
      create(:page_element, element: ref_question, page: page)
      ref_sheet = create(:reference_sheet, applicant_answer_sheet: answer_sheet, question: ref_question)
      create(:email_template, name: 'Reference Invite')
      create(:email_template, name: 'Reference Notification to Applicant')

      xhr :post, :send_reference_invite, reference: { ref_sheet.id.to_s => { relationship: 'rel', title: 'title', first_name: 'first_name', last_name: 'last_name', phone: 'phone', email: 'email@email.com' } }, reference_id: ref_sheet.id, id: answer_sheet.id
      ref_sheet.reload
      expect(ref_sheet.relationship).to eq('rel')
      expect(ref_sheet.title).to eq('title')
      expect(ref_sheet.first_name).to eq('first_name')
      expect(ref_sheet.last_name).to eq('last_name')
      expect(ref_sheet.phone).to eq('phone')
      expect(ref_sheet.email).to eq('email@email.com')
    end
  end
end
