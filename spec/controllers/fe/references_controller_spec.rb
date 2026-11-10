require 'rails_helper'

describe Fe::ReferencesController, type: :controller do
  let(:sheet) { create(:answer_sheet) }

  def draw_routes
    with_routing do |set|
      set.draw do
        get 'fe/references/:application_id/:id/edit' => 'fe/references#edit'
        get 'fe/references/:application_id/:id' => 'fe/references#show'
      end
      self.routes = set
      yield
    end
  end

  context 'when the host denies the answer sheet' do
    before { allow(controller).to receive(:fe_can_use_answer_sheet?).and_return(false) }

    it 'returns 403 for edit' do
      draw_routes { get :edit, params: {application_id: sheet.id, id: 'key'} }

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 403 for show' do
      draw_routes { get :show, params: {application_id: sheet.id, id: 'key'} }

      expect(response).to have_http_status(:forbidden)
    end
  end
end
