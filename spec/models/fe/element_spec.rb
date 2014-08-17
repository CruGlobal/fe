require 'rails_helper'

describe Fe::Element do
  it { expect belong_to :question_grid }  
  it { expect belong_to :choice_field }  
  it { expect have_many :page_elements }
  it { expect have_many :pages }
  it { expect validate_presence_of :kind }
  # it { expect validate_presence_of :style } # this isn't working
  it { expect ensure_length_of :kind }
  it { expect ensure_length_of :style }

  it "should update a conditional question if added after that question" do
    question_sheet = FactoryGirl.create(:question_sheet_with_pages)
    conditional_el = FactoryGirl.create(:choice_field_element, label: "This is a test for a yes/no question that will hide the next element", conditional_type: "Fe::Element")
    question_sheet.pages.reload
    question_sheet.pages[3].elements << conditional_el
    element = FactoryGirl.create(:text_field_element, label: "This is a test of a short answer that will be hidden by the previous elemenet", conditional_type: nil, conditional_answer: nil)
    question_sheet.pages[3].elements << element
    conditional_el.reload
    expect(conditional_el.conditional).to eq(element)
  end

  it "should update a conditional question if elements are moved around" do
    question_sheet = FactoryGirl.create(:question_sheet_with_pages)
    conditional_el = FactoryGirl.create(:choice_field_element, label: "This is a test for a yes/no question that will hide the next element", conditional_type: "Fe::Element")
    question_sheet.pages.reload
    question_sheet.pages[3].elements << conditional_el
    element = FactoryGirl.create(:text_field_element, label: "This is a test of a short answer that will be moved", conditional_type: nil, conditional_answer: nil)
    question_sheet.pages[3].elements << element
    element2 = FactoryGirl.create(:text_field_element, label: "This is a test of a short answer that will be moved to become hidden", conditional_type: nil, conditional_answer: nil)
    question_sheet.pages[3].elements << element2

    element.reload
    element2.reload
    conditional_el.reload

    # currently, page has elements in this order: conditional, element, element2
    # now swap the last 2 elements
    old_element_position = element.position(question_sheet.pages[3])
    old_element2_position = element2.position(question_sheet.pages[3])
    element.page_elements.first.update_attributes(position: old_element2_position)
    element2.page_elements.first.update_attributes(position: old_element_position)

    conditional_el.reload
    expect(conditional_el.conditional).to eq(element2)
  end

  it "should not require a hidden element" do
    question_sheet = FactoryGirl.create(:question_sheet_with_pages)
    conditional_el = FactoryGirl.create(:choice_field_element, label: "This is a test for a yes/no question that will hide the next element if the answer is yes", conditional_type: "Fe::Element", conditional_answer: "yes")
    question_sheet.pages.reload
    question_sheet.pages[3].elements << conditional_el
    element = FactoryGirl.create(:text_field_element, label: "This is a test of a short answer that is be hidden by the previous elemenet")
    question_sheet.pages[3].elements << element
    conditional_el.reload
    expect(conditional_el.conditional).to eq(element)

    # set up an answer sheet
    application = FactoryGirl.create(:answer_sheet)
    application.answer_sheet_question_sheets.first.update_attributes(question_sheet_id: question_sheet.id)
    
    # make the answer to the conditional question 'yes' so that the next element shouldn't be required
    conditional_el.set_response("yes", application)
    conditional_el.save_response(application)

    # validate the page -- the next element after the conditional should not be required
    page = question_sheet.pages[3]
    expect(page.complete?(application)).to eq(true)
  end

  it "should set the conditional page if a new conditional page element is created" do
    question_sheet = FactoryGirl.create(:question_sheet_with_pages)
    hide_page = question_sheet.pages[4]
    conditional_el = FactoryGirl.create(:choice_field_element, label: "This is a test for a yes/no question that will hide the next pag", conditional_type: "Fe::Page", conditional_id: hide_page.id)
    question_sheet.pages.reload
    question_sheet.pages[3].elements << conditional_el
    conditional_el.reload
    expect(conditional_el.conditional).to eq(hide_page)
  end

  it "should keep the conditional page if a page is moved" do
    question_sheet = FactoryGirl.create(:question_sheet_with_pages)
    hide_page = question_sheet.pages[4]
    conditional_el = FactoryGirl.create(:choice_field_element, label: "This is a test for a yes/no question that will hide the next pag", conditional_type: "Fe::Page", conditional_id: hide_page.id)
    question_sheet.pages.reload
    question_sheet.pages[3].elements << conditional_el
    conditional_el.reload
    expect(conditional_el.conditional).to eq(question_sheet.pages[4])

    # move some pages around
    question_sheet.pages[0].update_attributes number: 1
    question_sheet.pages[1].update_attributes number: 2
    question_sheet.pages[2].update_attributes number: 3
    question_sheet.pages[3].update_attributes number: 0 # the page the conditional element is on
    question_sheet.pages[4].update_attributes number: 4
    question_sheet.pages.reload

    # the page after the conditional page should still be set to the same page
    conditional_el.reload
    expect(conditional_el.conditional).to eq(hide_page)
  end

  it "should not require questions in a hidden page" do
    question_sheet = FactoryGirl.create(:question_sheet_with_pages)
    hide_page = question_sheet.pages[4]
    conditional_el = FactoryGirl.create(:choice_field_element, label: "This is a test for a yes/no question that will hide the next pag", conditional_type: "Fe::Page", conditional_id: hide_page.id, conditional_answer: "yes")
    question_sheet.pages.reload
    question_sheet.pages[3].elements << conditional_el
    conditional_el.reload
    expect(conditional_el.conditional).to eq(question_sheet.pages[4])

    # add required element on hidden page
    element = FactoryGirl.create(:text_field_element, label: "This is a test of a short answer on a hidden page")
    hide_page.elements << element

    # set up an answer sheet
    application = FactoryGirl.create(:answer_sheet)
    application.answer_sheet_question_sheets.first.update_attributes(question_sheet_id: question_sheet.id)

     # validate the hidden page, it should not be complete
    expect(hide_page.complete?(application)).to eq(false)

    # make the answer to the conditional question 'yes' so that the page shouldn't be required
    conditional_el.set_response("yes", application)
    conditional_el.save_response(application)

    # validate the hidden page, it should be marked complete because of being hidden
    expect(hide_page.complete?(application)).to eq(true)
  end
end
