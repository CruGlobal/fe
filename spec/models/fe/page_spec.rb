require 'rails_helper'

describe Fe::Page do
  it { expect belong_to :question_sheet }
  it { expect have_many :page_elements }
  it { expect have_many :elements }
  it { expect have_many :questions }
  it { expect have_many :question_grids }
  it { expect have_many :question_grid_with_totals }
  # it { expect validate_presence_of :label } # this isn't working
  # it { expect validate_presence_of :number } # this isn't working
  it { expect ensure_length_of :label }
  # it { expect validate_numericality_of :number }

  it "should not require a hidden element" do
    question_sheet = FactoryGirl.create(:question_sheet_with_pages)
    conditional_el = FactoryGirl.create(:choice_field_element, label: "This is a test for a yes/no question that will hide the next element if the answer is yes", conditional_type: "Fe::Element", conditional_answer: "yes")
    question_sheet.pages.reload
    question_sheet.pages[3].elements << conditional_el
    element = FactoryGirl.create(:text_field_element, label: "This is a test of a short answer that is made visible by the previous elemenet")
    question_sheet.pages[3].elements << element
    conditional_el.reload
    expect(conditional_el.conditional).to eq(element)

    # set up an answer sheet
    application = FactoryGirl.create(:answer_sheet)
    application.answer_sheet_question_sheet = FactoryGirl.create(:answer_sheet_question_sheet, answer_sheet: application, question_sheet: question_sheet)
    application.answer_sheet_question_sheets.first.update_attributes(question_sheet_id: question_sheet.id)

    # make the answer to the conditional question 'yes' so that the next element shows up and is thus required
    conditional_el.set_response("no", application)
    conditional_el.save_response(application)

    # validate the page -- the next element after the conditional should not be required
    page = question_sheet.pages[3]
    expect(page.complete?(application)).to eq(true)

    # make the answer to the conditional question 'yes' so that the next element shows up and is thus required
    conditional_el.set_response("yes", application)
    conditional_el.save_response(application)

    # validate the page -- the next element after the conditional should not be required
    page = question_sheet.pages[3]
    expect(page.complete?(application)).to eq(false)
  end

  context '#all_elements' do
    it 'should include elements in a grid' do
      p = create(:page)
      e = create(:question_grid)
      create(:page_element, page: p, element: e)
      tf1 = create(:text_field_element, question_grid: e)

      # add text field directly to page
      tf2 = create(:text_field_element)
      create(:page_element, page: p, element: tf2)

      # add section to grid
      section = create(:section, question_grid: e)

      p.reload # get the updated all_element_ids column
      expect(p.all_elements).to eq([e, tf1, tf2, section])
    end
    it 'should return an empty active record result set when no elements are added' do
      p = create(:page)
      expect(p.all_elements).to eq([])
    end
    it 'should rebuild_all_element_ids first when not set' do
      p = create(:page)
      p.all_elements
      p.reload
      expect(p.all_element_ids).to eq('')
    end
  end
  context '#has_questions?' do
    it 'should return true when there is a question directly on the page' do
      p = create(:page)
      e = create(:text_field_element)
      create(:page_element, page: p, element: e)
      expect(p.has_questions?).to be true
    end
    it 'should not count a non-question directly on the page' do
      p = create(:page)
      e = create(:section)
      create(:page_element, page: p, element: e)
      expect(p.has_questions?).to be false
    end
    it 'should return true when the only question is in a grid' do
      p = create(:page)
      e = create(:question_grid)
      create(:page_element, page: p, element: e)
      tf1 = create(:text_field_element, question_grid: e)
      section = create(:section, question_grid: e)
      p.reload # get the updated all_element_ids column
      expect(p.has_questions?).to be true
    end
    it 'should not count a non-question inside a grid as a question' do
      p = create(:page)
      e = create(:question_grid)
      create(:page_element, page: p, element: e)
      section = create(:section, question_grid: e)
      p.reload # get the updated all_element_ids column
      expect(p.has_questions?).to be false
    end
  end
  context '#all_questions' do
    it 'should include elements in a grid with total' do
      p = create(:page)
      e = create(:question_grid_with_total) # shouldn't be included in all_questions because it's a not a question
      create(:page_element, page: p, element: e)
      tf1 = create(:text_field_element, question_grid: e)
      tf2 = create(:text_field_element) # add directly to page
      create(:page_element, page: p, element: tf2)
      section = create(:section, question_grid: e) # shouldn't be included in all_questions because it's not a question
      p.reload # get the updated all_element_ids column
      expect(p.all_questions).to eq([tf1, tf2])
    end
  end
  context '#rebuild_all_element_ids' do
    it 'should include elements in a grid' do
      p = create(:page)
      e = create(:question_grid)
      create(:page_element, page: p, element: e)
      tf1 = create(:text_field_element, question_grid: e)
      tf2 = create(:text_field_element) # add directly to page
      create(:page_element, page: p, element: tf2)
      section = create(:section, question_grid: e)
      p.update_column :all_element_ids, nil
      p.rebuild_all_element_ids
      expect(p.all_element_ids).to eq("#{e.id},#{tf2.id},#{tf1.id},#{section.id}")
    end
  end
end
