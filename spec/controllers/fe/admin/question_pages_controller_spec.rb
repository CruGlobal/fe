require 'rails_helper'

describe Fe::Admin::QuestionPagesController, type: :controller do
  context '#show' do
    it 'should work' do
      page = create(:page)
      question_sheet = page.question_sheet
      get :show, params: {question_sheet_id: question_sheet.id, id: page.id}, xhr: true
    end
  end
end

describe Fe::Admin::QuestionPagesController, type: :controller do
  it 'returns 403 on #show when the host says the person is not an admin' do
    allow(controller).to receive(:fe_admin?).and_return(false)
    page = create(:page)
    get :show, params: {question_sheet_id: page.question_sheet.id, id: page.id}, xhr: true
    expect(response).to have_http_status(:forbidden)
  end
end
