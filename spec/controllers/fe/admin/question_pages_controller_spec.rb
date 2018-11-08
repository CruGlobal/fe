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
