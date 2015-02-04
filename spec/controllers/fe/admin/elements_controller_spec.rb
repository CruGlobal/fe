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

      expect {
        xhr :post, :create, element_type: 'Fe::TextField', element: { style: 'style' }, question_sheet_id: question_sheet.id, page_id: page.id
      }.to change{Fe::Element.count}.by(1)

      expect(assigns(:page_element)).to_not be_nil
      new_element = Fe::Element.last
      expect(assigns(:page_element).element).to eq(new_element)
      expect(assigns(:page_element).page).to eq(page)
    end
    it 'should handle error saving element' do
      answer_sheet = create(:answer_sheet)
      page = create(:page)
      question_sheet = page.question_sheet
      create(:answer_sheet_question_sheet, answer_sheet: answer_sheet, question_sheet: question_sheet)

      expect {
        xhr :post, :create, element_type: 'Fe::TextField', element: { slug: "Illegal Chars: #@$!" }, question_sheet_id: question_sheet.id, page_id: page.id
      }.to change{Fe::Element.count}.by(0)

      expect(assigns(:page_element)).to be_nil
      expect(response).to render_template('error.js.erb')
    end
  end
  context '#update' do
    it 'should work' do
      answer_sheet = create(:answer_sheet)
      page = create(:page)
      question_sheet = page.question_sheet
      create(:answer_sheet_question_sheet, answer_sheet: answer_sheet, question_sheet: question_sheet)
      element = create(:text_field_element, style: 'style')
      create(:page_element, element: element, page: page)

      xhr :put, :update, element: { style: 'style' }, question_sheet_id: question_sheet.id, page_id: page.id, id: element.id

      expect(assigns(:element)).to eq(element)
      expect(assigns(:element).style).to eq('style')
    end
    it 'should handle error saving element' do
      answer_sheet = create(:answer_sheet)
      page = create(:page)
      question_sheet = page.question_sheet
      create(:answer_sheet_question_sheet, answer_sheet: answer_sheet, question_sheet: question_sheet)
      element = create(:text_field_element, style: 'style')
      create(:page_element, element: element, page: page)

      xhr :put, :update, element: { slug: "Illegal Chars: #@$!" }, question_sheet_id: question_sheet.id, page_id: page.id, id: element.id
      expect(assigns(:element)).to eq(element)
      expect(response).to render_template('error.js.erb')
    end
  end
  context '#destroy' do
    it 'should destroy the element when it is not used in any other pages' do
      answer_sheet = create(:answer_sheet)
      page = create(:page)
      question_sheet = page.question_sheet
      create(:answer_sheet_question_sheet, answer_sheet: answer_sheet, question_sheet: question_sheet)
      element = create(:text_field_element, style: 'style')
      create(:page_element, element: element, page: page)

      xhr :delete, :destroy, question_sheet_id: question_sheet.id, page_id: page.id, id: element.id

      expect(Fe::PageElement.find_by(page_id: page.id, element_id: element.id)).to be_nil
      expect(Fe::Element.find_by(id: element.id)).to be_nil
    end
    it 'should not destroy the element when it is not used in any other pages, but it has answers' do
      answer_sheet = create(:answer_sheet)
      page = create(:page)
      question_sheet = page.question_sheet
      create(:answer_sheet_question_sheet, answer_sheet: answer_sheet, question_sheet: question_sheet)
      element = create(:text_field_element, style: 'style')
      create(:page_element, element: element, page: page)
      create(:answer, question: element, value: 'answer here', answer_sheet: answer_sheet)

      #binding.pry
      xhr :delete, :destroy, question_sheet_id: question_sheet.id, page_id: page.id, id: element.id

      expect(Fe::PageElement.find_by(page_id: page.id, element_id: element.id)).to be_nil
      expect(Fe::Element.find_by(id: element.id)).to_not be_nil
    end
    it 'should not destroy the element when it has no answers, but is being used in another page' do
      answer_sheet = create(:answer_sheet)
      page = create(:page)
      page2 = create(:page)
      question_sheet = page.question_sheet
      create(:answer_sheet_question_sheet, answer_sheet: answer_sheet, question_sheet: question_sheet)
      element = create(:text_field_element, style: 'style')
      create(:page_element, element: element, page: page)
      create(:page_element, element: element, page: page2)

      #binding.pry
      xhr :delete, :destroy, question_sheet_id: question_sheet.id, page_id: page.id, id: element.id

      expect(Fe::PageElement.find_by(page_id: page.id, element_id: element.id)).to be_nil
      expect(Fe::Element.find_by(id: element.id)).to_not be_nil
    end
  end
end
