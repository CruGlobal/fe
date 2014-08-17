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
    conditional_el = Fe::ChoiceField.create!({"kind"=>"Fe::ChoiceField", "style"=>"yes-no", "label"=>"This is a test for a yes/no question that will hide the next element", "content"=>"Choice One\r\nChoice Two\r\nChoice Three", "required"=>true, "slug"=>"", "position"=>nil, "is_confidential"=>false, "source"=>"", "value_xpath"=>"", "text_xpath"=>"", "object_name"=>"", "attribute_name"=>"", "question_grid_id"=>nil, "cols"=>nil, "total_cols"=>nil, "css_id"=>nil, "css_class"=>nil, "related_question_sheet_id"=>nil, "conditional_id"=>nil, "tooltip"=>"", "hide_label"=>false, "hide_option_labels"=>false, "max_length"=>nil, "conditional_type"=>"Fe::Element", "conditional_answer"=>"yes"})
    question_sheet.pages.reload
    question_sheet.pages[3].elements << conditional_el
    element = Fe::TextField.create!({"kind"=>"Fe::TextField", "style"=>"short", "label"=>"This is a test of a short answer that will be hidden by the previous elemenet", "content"=>nil, "required"=>true, "slug"=>"", "position"=>nil, "is_confidential"=>false, "source"=>nil, "value_xpath"=>nil, "text_xpath"=>nil, "object_name"=>"", "attribute_name"=>"", "question_grid_id"=>nil, "cols"=>nil, "total_cols"=>nil, "css_id"=>nil, "css_class"=>nil, "related_question_sheet_id"=>nil, "conditional_id"=>529, "tooltip"=>"", "hide_label"=>false, "hide_option_labels"=>false, "max_length"=>nil, "conditional_type"=>nil, "conditional_answer"=>nil})
    question_sheet.pages[3].elements << element
    conditional_el.reload
    expect(conditional_el.conditional).to eq(element)
  end

  it "should update a conditional question if elements are moved around" do
    question_sheet = FactoryGirl.create(:question_sheet_with_pages)
    conditional_el = Fe::ChoiceField.create!({"kind"=>"Fe::ChoiceField", "style"=>"yes-no", "label"=>"This is a test for a yes/no question that will hide the next element", "content"=>"Choice One\r\nChoice Two\r\nChoice Three", "required"=>true, "slug"=>"", "position"=>nil, "is_confidential"=>false, "source"=>"", "value_xpath"=>"", "text_xpath"=>"", "object_name"=>"", "attribute_name"=>"", "question_grid_id"=>nil, "cols"=>nil, "total_cols"=>nil, "css_id"=>nil, "css_class"=>nil, "related_question_sheet_id"=>nil, "conditional_id"=>nil, "tooltip"=>"", "hide_label"=>false, "hide_option_labels"=>false, "max_length"=>nil, "conditional_type"=>"Fe::Element", "conditional_answer"=>"yes"})
    question_sheet.pages.reload
    question_sheet.pages[3].elements << conditional_el
    element = Fe::TextField.create!({"kind"=>"Fe::TextField", "style"=>"short", "label"=>"This is an element that will be moved to the bottom", "content"=>nil, "required"=>true, "slug"=>"", "position"=>nil, "is_confidential"=>false, "source"=>nil, "value_xpath"=>nil, "text_xpath"=>nil, "object_name"=>"", "attribute_name"=>"", "question_grid_id"=>nil, "cols"=>nil, "total_cols"=>nil, "css_id"=>nil, "css_class"=>nil, "related_question_sheet_id"=>nil, "conditional_id"=>529, "tooltip"=>"", "hide_label"=>false, "hide_option_labels"=>false, "max_length"=>nil, "conditional_type"=>nil, "conditional_answer"=>nil})
    question_sheet.pages[3].elements << element
    element2 = Fe::TextField.create!({"kind"=>"Fe::TextField", "style"=>"short", "label"=>"This is a test of a short answer that will be moved up to become hidden", "content"=>nil, "required"=>true, "slug"=>"", "position"=>nil, "is_confidential"=>false, "source"=>nil, "value_xpath"=>nil, "text_xpath"=>nil, "object_name"=>"", "attribute_name"=>"", "question_grid_id"=>nil, "cols"=>nil, "total_cols"=>nil, "css_id"=>nil, "css_class"=>nil, "related_question_sheet_id"=>nil, "conditional_id"=>529, "tooltip"=>"", "hide_label"=>false, "hide_option_labels"=>false, "max_length"=>nil, "conditional_type"=>nil, "conditional_answer"=>nil})
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
    conditional_el = Fe::ChoiceField.create!({"kind"=>"Fe::ChoiceField", "style"=>"yes-no", "label"=>"This is a test for a yes/no question that will hide the next element if the answer is yes", "content"=>"Choice One\r\nChoice Two\r\nChoice Three", "required"=>true, "slug"=>"", "position"=>nil, "is_confidential"=>false, "source"=>"", "value_xpath"=>"", "text_xpath"=>"", "object_name"=>"", "attribute_name"=>"", "question_grid_id"=>nil, "cols"=>nil, "total_cols"=>nil, "css_id"=>nil, "css_class"=>nil, "related_question_sheet_id"=>nil, "conditional_id"=>nil, "tooltip"=>"", "hide_label"=>false, "hide_option_labels"=>false, "max_length"=>nil, "conditional_type"=>"Fe::Element", "conditional_answer"=>"yes"})
    question_sheet.pages.reload
    question_sheet.pages[3].elements << conditional_el
    element = Fe::TextField.create!({"kind"=>"Fe::TextField", "style"=>"short", "label"=>"This is a test of a short answer that will be hidden by the previous elemenet", "content"=>nil, "required"=>true, "slug"=>"", "position"=>nil, "is_confidential"=>false, "source"=>nil, "value_xpath"=>nil, "text_xpath"=>nil, "object_name"=>"", "attribute_name"=>"", "question_grid_id"=>nil, "cols"=>nil, "total_cols"=>nil, "css_id"=>nil, "css_class"=>nil, "related_question_sheet_id"=>nil, "conditional_id"=>529, "tooltip"=>"", "hide_label"=>false, "hide_option_labels"=>false, "max_length"=>nil, "conditional_type"=>nil, "conditional_answer"=>nil})
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
end
