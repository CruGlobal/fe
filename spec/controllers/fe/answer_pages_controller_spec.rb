require 'rails_helper'

describe Fe::AnswerPagesController, type: :controller do
  context '#edit' do
    it 'should work' do
      answer_sheet = create(:answer_sheet)
      page = create(:page)
      question_sheet = page.question_sheet
      create(:answer_sheet_question_sheet, answer_sheet: answer_sheet, question_sheet: question_sheet)
      get :edit, id: page.id, answer_sheet_id: answer_sheet.id
      expect(response).to render_template('fe/answer_pages/_answer_page')
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
      xhr :put, :update, answers: { "#{element.id}" => 'answer here' }, id: page.id, answer_sheet_id: answer_sheet.id
      expect(response).to render_template('fe/answer_pages/update')
      expect(Fe::Answer.find_by(answer_sheet_id: answer_sheet.id, question_id: element.id))
      expect(Fe::Answer.find_by(answer_sheet_id: answer_sheet.id, question_id: element.id).value).to eq('answer here')
    end
  end

end
