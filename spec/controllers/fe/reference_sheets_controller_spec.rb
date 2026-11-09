require 'rails_helper'

describe Fe::ReferenceSheetsController, type: :controller do
  it 'renders not_found for a wrong access key without asking the host' do
    reference_sheet = create(:reference_sheet)
    expect(controller).not_to receive(:fe_can_use_answer_sheet?)

    get :edit, params: {id: reference_sheet.id, a: 'wrong'}

    expect(response).to render_template('fe/reference_sheets/not_found')
  end

  context 'with a valid access key' do
    let(:ref_qs) { create(:question_sheet) }
    let(:question) { create(:reference_question, related_question_sheet: ref_qs) }
    let(:applicant_sheet) { create(:answer_sheet, applicant_id: create(:fe_person).id) }
    let(:reference_sheet) { create(:reference_sheet, question: question, applicant_answer_sheet: applicant_sheet, access_key: 'good-key') }

    before { ref_qs.pages << create(:page) }

    it 'stops show with a 404' do
      get :show, params: {id: reference_sheet.id, a: 'good-key'}

      expect(response).to have_http_status(:not_found)
      expect(assigns(:elements)).to be_nil
    end

    it 'stops submit with a 404 even when a host app routes it' do
      with_routing do |set|
        set.draw { post 'fe/reference_sheets/:id/submit', to: 'fe/reference_sheets#submit' }

        self.routes = set

        expect {
          post :submit, params: {id: reference_sheet.id, a: 'good-key'}
        }.not_to change { reference_sheet.reload.status }
      end

      expect(response).to have_http_status(:not_found)
    end

    it 'still renders edit' do
      get :edit, params: {id: reference_sheet.id, a: 'good-key'}

      expect(response).to render_template('fe/answer_sheets/edit')
    end
  end
end
