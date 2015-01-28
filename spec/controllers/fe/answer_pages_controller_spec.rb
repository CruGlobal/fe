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
      puts "\nFe::AnswerPagesController #update should work START"
      puts "\nFe::AnswerPagesController #update answers in the system at this point: #{Fe::Answer.all.inspect}"

      answer_sheet = create(:answer_sheet)
      page = create(:page)
      question_sheet = page.question_sheet
      create(:answer_sheet_question_sheet, answer_sheet: answer_sheet, question_sheet: question_sheet)
      element = create(:text_field_element)
      create(:page_element, element: element, page: page)
      # ref
      reference_question = create(:reference_question)
      reference_sheet = create(:reference_sheet, applicant_answer_sheet_id: answer_sheet.id, email: 'initial@ref.com')

      puts "\nFe::AnswerPagesController #update should work DONE SETUP, CALLING PUT"

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

      puts "\nFe::AnswerPagesController #update should work DONE PUT"
      puts "\nFe::AnswerPagesController #update should work, answers in the system at this point: #{Fe::Answer.all.inspect}"
      expect(response).to render_template('fe/answer_pages/update')
      expect(Fe::Answer.find_by(answer_sheet_id: answer_sheet.id, question_id: element.id).value).to eq('answer here')
      expect(reference_sheet.reload.email).to eq('email@reference.com')
      puts "\nFe::AnswerPagesController #update should work END"
    end
  end

end
