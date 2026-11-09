require 'rails_helper'

describe Fe::SubmitPagesController, type: :controller do
  render_views false

  let(:sheet) { create(:answer_sheet) }

  def draw_routes
    with_routing do |set|
      set.draw do
        get 'fe/submit_pages/:application_id/edit' => 'fe/submit_pages#edit'
        put 'fe/submit_pages/:application_id' => 'fe/submit_pages#update'
      end
      self.routes = set
      yield
    end
  end

  context 'when the host denies the answer sheet' do
    before { allow(controller).to receive(:fe_can_use_answer_sheet?).and_return(false) }

    it 'returns 403 for edit' do
      draw_routes { get :edit, params: {application_id: sheet.id} }

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 403 for update' do
      draw_routes { put :update, params: {application_id: sheet.id} }

      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'when the host allows the answer sheet' do
    before do
      allow(controller).to receive(:fe_can_use_answer_sheet?).and_return(true)
      allow(controller).to receive(:next_custom_page)
    end

    it 'returns 200 for edit' do
      draw_routes { get :edit, params: {application_id: sheet.id} }

      expect(response).to have_http_status(:ok)
    end
  end
end
