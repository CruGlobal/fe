require 'rails_helper'

describe Fe::ReferencePagesController, type: :controller do
  let(:sheet) { create(:answer_sheet) }

  def draw_routes
    with_routing do |set|
      set.draw do
        get 'fe/reference_pages/:application_id/edit' => 'fe/reference_pages#edit'
        put 'fe/reference_pages/:application_id' => 'fe/reference_pages#update'
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
end
