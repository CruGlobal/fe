require 'rails_helper'

# when using a decorator in the enclosing app I get an error, don't have the time to
# figure it out and since it's low priority since we're just testing, doing it here
# should be fine
Fe::Application.class_eval do
  belongs_to :applicant, foreign_key: 'applicant_id', class_name: 'Person'
end

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

  it "should not let a hidden page make the questionnaire incomplete" do
    question_sheet = FactoryGirl.create(:question_sheet_with_pages)
    hide_page = question_sheet.pages[4]
    conditional_el = FactoryGirl.create(:choice_field_element, label: "This is a test for a yes/no question that will hide the next page", conditional_type: "Fe::Page", conditional_id: hide_page.id, conditional_answer: "yes")
    question_sheet.pages.reload
    question_sheet.pages[3].elements << conditional_el
    conditional_el.reload
    expect(conditional_el.conditional).to eq(question_sheet.pages[4])

    # add required element on hidden page
    element = FactoryGirl.create(:text_field_element, label: "This is a test of a short answer on a hidden page")
    hide_page.elements << element

    # set up an answer sheet
    application = FactoryGirl.create(:answer_sheet)
    application.answer_sheet_question_sheet = FactoryGirl.create(:answer_sheet_question_sheet, answer_sheet: application, question_sheet: question_sheet)
    application.answer_sheet_question_sheets.first.update_attributes(question_sheet_id: question_sheet.id)

    # validate the hidden page, it should be marked complete
    expect(hide_page.complete?(application)).to eq(true)

    # make the answer to the conditional question 'yes' so that the element shows up and is thus required
    conditional_el.set_response("yes", application)
    conditional_el.save_response(application)

    # validate the now-visible  page, it should be marked not complete
    expect(hide_page.complete?(application)).to eq(false)
  end

  it "should not require questions in a hidden page" do
    question_sheet = FactoryGirl.create(:question_sheet_with_pages)
    hide_page = question_sheet.pages[4]
    conditional_el = FactoryGirl.create(:choice_field_element, label: "This is a test for a yes/no question that will hide the next page", conditional_type: "Fe::Page", conditional_id: hide_page.id, conditional_answer: "yes")
    question_sheet.pages.reload
    question_sheet.pages[3].elements << conditional_el
    conditional_el.reload
    expect(conditional_el.conditional).to eq(question_sheet.pages[4])

    # add required element on hidden page
    element = FactoryGirl.create(:text_field_element, label: "This is a test of a short answer on a hidden page")
    hide_page.elements << element

    # set up an answer sheet
    application = FactoryGirl.create(:answer_sheet)
    application.answer_sheet_question_sheet = FactoryGirl.create(:answer_sheet_question_sheet, answer_sheet: application, question_sheet: question_sheet)
    application.answer_sheet_question_sheets.first.update_attributes(question_sheet_id: question_sheet.id)

    # make the answer to the conditional question 'yes' (match) so that the element is visible (and thus required)
    conditional_el.set_response("yes", application)
    conditional_el.save_response(application)

    # validate the hidden page, it should not be complete
    expect(hide_page.complete?(application)).to eq(false)

    # make the answer to the conditional question 'no' (no match) so that the element is hidden
    conditional_el.set_response("no", application)
    conditional_el.save_response(application)

    # validate the hidden page, it should be marked complete because of being hidden
    expect(hide_page.complete?(application)).to eq(true)
  end

  it "should return false for has_response?" do
    element = Fe::Element.new
    expect(element.has_response?).to be false
  end

  context '#limit' do
    it "should return a value for a legitimate object_name and attribute_name" do
      application = FactoryGirl.create(:application)
      application.applicant_id = create(:fe_person).id
      puts "application.applicant: #{application.applicant.inspect}"
      element = Fe::Element.new object_name: 'applicant', attribute_name: 'first_name'
      limit = element.limit(application)
      puts "limit response: #{limit.inspect}"
      begin
        puts Fe::Person.connection.execute("select column_name, data_type, character_maximum_length from INFORMATION_SCHEMA.COLUMNS where table_name = '#{Fe::Person.table_name}'").to_a.inspect
      rescue
      end
      expect(limit).to_not be_nil
    end
=begin
    it "should return nil instead of crashing if there's an exception thrown" do
      application = FactoryGirl.create(:application)
      application.applicant_id = create(:fe_person).id
      element = Fe::Element.new object_name: 'applicant', attribute_name: 'asdf'
      expect(element.limit(application)).to be_nil
    end
=end
  end
end
