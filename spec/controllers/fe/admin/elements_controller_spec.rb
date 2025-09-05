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

      get :edit, params: {question_sheet_id: question_sheet.id, page_id: page.id, id: element.id}, xhr: true
      expect(assigns(:element)).to eq(element)
    end
  end
  context '#new' do
    it 'should work' do
      answer_sheet = create(:answer_sheet)
      page = create(:page)
      question_sheet = page.question_sheet
      create(:answer_sheet_question_sheet, answer_sheet: answer_sheet, question_sheet: question_sheet)
      element1 = create(:text_field_element, style: 'style', share: true)
      element2 = create(:text_field_element, style: 'style', share: false)
      create(:page_element, element: element1, page: page)
      create(:page_element, element: element2, page: page)

      get :new, params: {element_type: 'Fe::TextField', element: { style: 'style' }, question_sheet_id: question_sheet.id, page_id: page.id}, xhr: true
      expect(assigns(:questions)).to eq([element1])
    end
  end
  context '#use_existing' do
    it 'should work' do
      answer_sheet = create(:answer_sheet)
      page = create(:page)
      question_sheet = page.question_sheet
      create(:answer_sheet_question_sheet, answer_sheet: answer_sheet, question_sheet: question_sheet)
      element = create(:text_field_element, style: 'style')

      get :use_existing, params: {question_sheet_id: question_sheet.id, page_id: page.id, id: element.id}, xhr: true
      expect(assigns(:page_element)).to_not be_nil
      expect(assigns(:page_element)).to_not be_nil
      expect(assigns(:page)).to eq(page)
      expect(assigns(:page_element).element).to eq(element)
    end
  end
  context '#copy_existing' do
    it 'should work' do
      answer_sheet = create(:answer_sheet)
      page = create(:page)
      question_sheet = page.question_sheet
      create(:answer_sheet_question_sheet, answer_sheet: answer_sheet, question_sheet: question_sheet)
      element = create(:text_field_element, style: 'style', share: true)

      get :copy_existing, params: {question_sheet_id: question_sheet.id, page_id: page.id, id: element.id}, xhr: true
      expect(assigns(:page_element)).to_not be_nil
      expect(assigns(:page_element)).to_not be_nil
      expect(assigns(:page)).to eq(page)
      expect(assigns(:page_element).element).to_not eq(element)
      expect(assigns(:page_element).element.share).to be false
    end
  end
  context '#create' do
    it 'should work' do
      answer_sheet = create(:answer_sheet)
      page = create(:page)
      question_sheet = page.question_sheet
      create(:answer_sheet_question_sheet, answer_sheet: answer_sheet, question_sheet: question_sheet)

      expect {
        post :create, params: {element_type: 'Fe::TextField', element: { style: 'style' }, question_sheet_id: question_sheet.id, page_id: page.id}, xhr: true
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
        post :create, params: {element_type: 'Fe::TextField', element: { slug: "Illegal Chars: #@$!" }, question_sheet_id: question_sheet.id, page_id: page.id}, xhr: true
      }.to change{Fe::Element.count}.by(0)

      expect(assigns(:page_element)).to be_nil
      expect(response).to render_template('error')
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

      put :update, params: {element: { style: 'style' }, question_sheet_id: question_sheet.id, page_id: page.id, id: element.id}, xhr: true

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

      put :update, params: {element: { slug: "Illegal Chars: #@$!" }, question_sheet_id: question_sheet.id, page_id: page.id, id: element.id}, xhr: true
      expect(assigns(:element)).to eq(element)
      expect(response).to render_template('error')
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

      delete :destroy, params: {question_sheet_id: question_sheet.id, page_id: page.id, id: element.id}, xhr: true

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

      delete :destroy, params: {question_sheet_id: question_sheet.id, page_id: page.id, id: element.id}, xhr: true

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

      delete :destroy, params: {question_sheet_id: question_sheet.id, page_id: page.id, id: element.id}, xhr: true

      expect(Fe::PageElement.find_by(page_id: page.id, element_id: element.id)).to be_nil
      expect(Fe::Element.find_by(id: element.id)).to_not be_nil
    end
  end

  context '#reorder' do
    it 'should work inside a question grid' do
      answer_sheet = create(:answer_sheet)
      page = create(:page)
      question_sheet = page.question_sheet
      create(:answer_sheet_question_sheet, answer_sheet: answer_sheet, question_sheet: question_sheet)
      element = create(:text_field_element, style: 'style')
      element2 = create(:text_field_element, style: 'style')
      element3 = create(:question_grid, style: 'style')
      element4 = create(:text_field_element, style: 'style', question_grid_id: element3.id)
      element5 = create(:text_field_element, style: 'style', question_grid_id: element3.id)
      create(:page_element, element: element, page: page)
      create(:page_element, element: element2, page: page)
      create(:page_element, element: element3, page: page)

      page_element_positions_before = Fe::PageElement.all.pluck(:position)

      post :reorder, params: {question_sheet_id: question_sheet.id, page_id: page.id, "questions_list_#{element3.id}" => [ element5.id, element4.id ]}, xhr: true
      # it shouldn't touch the page elements
      expect(Fe::PageElement.all.pluck(:position)).to eq(page_element_positions_before)
      # it should put a new order on the question grid elements
      expect(element5.reload.position).to eq(1)
      expect(element4.reload.position).to eq(2)
    end
    it 'should work outside a question grid' do
      answer_sheet = create(:answer_sheet)
      page = create(:page)
      question_sheet = page.question_sheet
      create(:answer_sheet_question_sheet, answer_sheet: answer_sheet, question_sheet: question_sheet)
      element = create(:text_field_element, style: 'style')
      element2 = create(:text_field_element, style: 'style')
      element3 = create(:question_grid, style: 'style')
      element4 = create(:text_field_element, style: 'style', question_grid_id: element3.id)
      element5 = create(:text_field_element, style: 'style', question_grid_id: element3.id)
      pe1 = create(:page_element, element: element, page: page)
      pe2 = create(:page_element, element: element2, page: page)
      pe3 = create(:page_element, element: element3, page: page)

      question_grid_elements_positions_before = element3.reload.elements.pluck(:position)

      post :reorder, params: {question_sheet_id: question_sheet.id, page_id: page.id, "questions_list" => [ element3.id, element.id, element2.id ]}, xhr: true
      # it shouldn't touch the question grid positions
      expect(element3.reload.elements.pluck(:position)).to eq(question_grid_elements_positions_before)
      # it should put a new order on the page elements
      expect(pe3.reload.position).to eq(1)
      expect(pe1.reload.position).to eq(2)
      expect(pe2.reload.position).to eq(3)
    end
  end
end
