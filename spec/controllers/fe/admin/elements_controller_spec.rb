require 'rails_helper'

describe Fe::Admin::ElementsController, type: :controller do
  context '#show' do
    it 'should work' do
      answer_sheet = create(:answer_sheet)
      page = create(:page)
      question_sheet = page.question_sheet
      create(:answer_sheet_question_sheet, answer_sheet: answer_sheet, question_sheet: question_sheet)
      element = create(:text_field_element)
      create(:page_element, element: element, page: page)

      xhr :get, :edit, question_sheet_id: question_sheet.id, page_id: page.id, id: element.id
      expect(assigns(:element)).to eq(element)
    end
  end
  context '#new' do
    it 'should work' do
      answer_sheet = create(:answer_sheet)
      page = create(:page)
      question_sheet = page.question_sheet
      create(:answer_sheet_question_sheet, answer_sheet: answer_sheet, question_sheet: question_sheet)
      element = create(:text_field_element, style: 'style')
      create(:page_element, element: element, page: page)

      xhr :get, :new, element_type: 'Fe::TextField', element: { style: 'style' }, question_sheet_id: question_sheet.id, page_id: page.id
      expect(assigns(:questions)).to eq([element])
    end
  end
  context '#use_existing' do
    it 'should work' do
      answer_sheet = create(:answer_sheet)
      page = create(:page)
      question_sheet = page.question_sheet
      create(:answer_sheet_question_sheet, answer_sheet: answer_sheet, question_sheet: question_sheet)
      element = create(:text_field_element, style: 'style')

      xhr :get, :use_existing, question_sheet_id: question_sheet.id, page_id: page.id, id: element.id
      expect(assigns(:page_element)).to_not be_nil
    end
    it 'should not put the same question on a questionnaire twice' do
      answer_sheet = create(:answer_sheet)
      page = create(:page)
      question_sheet = page.question_sheet
      create(:answer_sheet_question_sheet, answer_sheet: answer_sheet, question_sheet: question_sheet)
      element = create(:text_field_element, style: 'style')
      create(:page_element, element: element, page: page)

      xhr :get, :use_existing, question_sheet_id: question_sheet.id, page_id: page.id, id: element.id
      expect(assigns(:page_element)).to be_nil
    end
  end
  context '#create' do
    it 'should work' do
      answer_sheet = create(:answer_sheet)
      page = create(:page)
      question_sheet = page.question_sheet
      create(:answer_sheet_question_sheet, answer_sheet: answer_sheet, question_sheet: question_sheet)
      element = create(:text_field_element, style: 'style')
      create(:page_element, element: element, page: page)

      xhr :get, :new, element_type: 'Fe::TextField', element: { style: 'style' }, question_sheet_id: question_sheet.id, page_id: page.id
      expect(assigns(:questions)).to eq([element])
    end
  end
end
