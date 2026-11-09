require 'rails_helper'

describe Fe::ReferenceSheetsController, type: :controller do
  it 'renders not_found for a wrong access key without asking the host' do
    reference_sheet = create(:reference_sheet)
    expect(controller).not_to receive(:fe_can_use_answer_sheet?)

    get :edit, params: {id: reference_sheet.id, a: 'wrong'}

    expect(response).to render_template('fe/reference_sheets/not_found')
  end

  it 'renders done' do
    with_routing do |set|
      set.draw { get 'fe/references/done' => 'fe/reference_sheets#done' }

      self.routes = set

      get :done
    end

    expect(response).to have_http_status(:ok)
    expect(response).to render_template('fe/reference_sheets/done')
  end

  context 'with a valid access key' do
    let(:ref_qs) { create(:question_sheet) }
    let(:question) { create(:reference_question, related_question_sheet: ref_qs) }
    let(:applicant_sheet) { create(:answer_sheet, applicant_id: create(:fe_person).id) }
    let(:reference_sheet) { create(:reference_sheet, question: question, applicant_answer_sheet: applicant_sheet, access_key: 'good-key') }

    before { ref_qs.pages << create(:page) }

    it 'renders show when the host allows it' do
      allow(controller).to receive(:fe_can_use_answer_sheet?).and_return(true)

      get :show, params: {id: reference_sheet.id, a: 'good-key'}

      expect(response).to have_http_status(:ok)
      expect(response).to render_template('fe/answer_sheets/show')
    end

    it 'asks the host for :look on show and returns 403 when it refuses' do
      expect(controller).to receive(:fe_can_use_answer_sheet?).with(reference_sheet, :look).and_return(false)

      get :show, params: {id: reference_sheet.id, a: 'good-key'}

      expect(response).to have_http_status(:forbidden)
    end

    it 'stops submit with a 404 before loading the sheet or asking the host' do
      expect(controller).not_to receive(:get_answer_sheet)
      expect(controller).not_to receive(:fe_can_use_answer_sheet?)

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
