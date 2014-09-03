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
end
