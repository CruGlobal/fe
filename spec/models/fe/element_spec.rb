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

  it "should not require an element with choice_field set that has a false value" do
    question_sheet = FactoryGirl.create(:question_sheet_with_pages)
    choice_field = FactoryGirl.create(:choice_field_element, label: "This is a test for a yes/no question that will hide the enclosed element", conditional_type: "Fe::Element")
    question_sheet.pages.reload
    question_sheet.pages[3].elements << choice_field
    element = FactoryGirl.create(:text_field_element, label: "This is a test of a short answer that will be hidden by the enclosing element", choice_field_id: choice_field.id, required: true)
    question_sheet.pages[3].elements << element

    application = FactoryGirl.create(:answer_sheet)
    application.question_sheets << question_sheet

    # make the answer to the conditional question 'no' so that the element is not required
    choice_field.set_response("no", application)
    choice_field.save_response(application)

    expect(element.required?(application)).to be false
  end

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

  context "in a grid" do
    it "should update a conditional question if added after that question" do
      question_sheet = FactoryGirl.create(:question_sheet_with_pages)
      question_grid = FactoryGirl.create(:question_grid)
      question_sheet.pages.reload
      question_sheet.pages[3].elements << question_grid

      conditional_el = FactoryGirl.create(:choice_field_element, label: "This is a test for a yes/no question that will hide the next element", conditional_type: "Fe::Element", question_grid_id: question_grid.id)
      element = FactoryGirl.create(:text_field_element, label: "This is a test of a short answer that will be hidden by the previous elemenet", conditional_type: nil, conditional_answer: nil, question_grid_id: question_grid.id)
      expect(conditional_el.reload.conditional).to eq(element)
    end

    it "should update the condition element" do
      question_sheet = FactoryGirl.create(:question_sheet_with_pages)
      question_grid = FactoryGirl.create(:question_grid)
      question_sheet.pages.reload
      question_sheet.pages[3].elements << question_grid

      conditional_el = FactoryGirl.create(:choice_field_element, label: "This is a test for a yes/no question that will hide the next element", conditional_type: "Fe::Element", question_grid_id: question_grid.id)
      element = FactoryGirl.create(:text_field_element, label: "This is a test of a short answer that will be hidden by the previous elemenet", conditional_type: nil, conditional_answer: nil, question_grid_id: question_grid.id)

      conditional_el.set_conditional_element
      expect(conditional_el.conditional).to eq(element)
    end
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

  it "should not require a nested element in nested hidden page" do
    question_sheet = FactoryGirl.create(:question_sheet_with_pages)
    conditional_el1 = FactoryGirl.create(:choice_field_element, label: 'LVL1')
    question_sheet.pages.reload
    question_sheet.pages[0].elements << conditional_el1

    conditional_el2 = FactoryGirl.create(:choice_field_element, label: 'LVL2', choice_field_id: conditional_el1.id)
    conditional_el2.reload

    group = FactoryGirl.create(:question_grid, choice_field_id: conditional_el2.id, label: 'LVL3 (GRID)')

    conditional_el3 = FactoryGirl.create(:choice_field_element, label: 'LVL4', question_grid_id: group.id)
    conditional_el3.reload

    # add required element on hidden group
    element = FactoryGirl.create(:text_field_element, label: "EL (LVL5)", choice_field_id: conditional_el3.id)

    # set up an answer sheet
    application = FactoryGirl.create(:answer_sheet)
    application.answer_sheet_question_sheet = FactoryGirl.create(:answer_sheet_question_sheet, answer_sheet: application, question_sheet: question_sheet)
    application.answer_sheet_question_sheets.first.update_attributes(question_sheet_id: question_sheet.id)

    # start with all the conditional element values yes so that the element will show
    conditional_el1.set_response("yes", application)
    conditional_el1.save_response(application)
    conditional_el2.set_response("yes", application)
    conditional_el2.save_response(application)
    conditional_el3.set_response("yes", application)
    conditional_el3.save_response(application)

    # the element should be visible at this point
    expect(element.visible?(application)).to be(true)

    # hide the second conditional element, that should hide the group and the element with it
    conditional_el2.set_response("no", application)
    conditional_el2.save_response(application)

    # the element should be hidden now
    element = Fe::Element.find(element.id)
    expect(element.visible?(application)).to be(false)
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
      element = Fe::Element.new object_name: 'applicant', attribute_name: 'first_name'
      expect(element.limit(application)).to_not be_nil
    end
    it "should return nil instead of crashing if there's an exception thrown" do
      application = FactoryGirl.create(:application)
      application.applicant_id = create(:fe_person).id
      element = Fe::Element.new object_name: 'applicant', attribute_name: 'asdf'
      expect(element.limit(application)).to be_nil
    end
  end

  context '#previous_element' do
    it "should work" do
      application = FactoryGirl.create(:application)
      application.applicant_id = create(:fe_person).id
      element1 = create(:text_field_element)
      element2 = create(:text_field_element)
      element3 = create(:text_field_element)
      page = create(:page)
      create(:page_element, page_id: page.id, element_id: element1.id)
      create(:page_element, page_id: page.id, element_id: element2.id)
      create(:page_element, page_id: page.id, element_id: element3.id)
      expect(element2.previous_element(page.question_sheet)).to eq(element1)
    end
  end

  context '#required' do
    it "should not require a conditional element when its prev element isn't matching the answer text" do
      application = FactoryGirl.create(:application)
      application.applicant_id = create(:fe_person).id
      element1 = create(:text_field_element)
      element2 = create(:text_field_element, conditional_answer: 'test')
      element3 = create(:text_field_element, required: true)
      # set conditional element to element3 (note that an element's conditional ref will always either be a page or the *next* element, never any other element than the next one)
      element2.conditional = element3
      element2.save!

      page = create(:page)
      question_sheet = page.question_sheet
      create(:page_element, page_id: page.id, element_id: element1.id)
      create(:page_element, page_id: page.id, element_id: element2.id)
      create(:page_element, page_id: page.id, element_id: element3.id)

      # set up an answer sheet
      application = FactoryGirl.create(:answer_sheet)
      application.answer_sheet_question_sheet = FactoryGirl.create(:answer_sheet_question_sheet, answer_sheet: application, question_sheet: question_sheet)
      application.answer_sheet_question_sheets.first.update_attributes(question_sheet_id: question_sheet.id)

      # make the answer to the conditional question 'yes' so that the element shows up and is thus required
      element2.set_response('nomatch', application)
      element2.save_response(application)

      expect(element3.required?(application)).to be false
    end
  end
  context '#clone' do
    it 'should duplicate question grid elements' do
      element1 = create(:question_grid)
      element2 = create(:text_field_element, question_grid_id: element1.id, position: 0) # added to grid
      element3 = create(:text_field_element, question_grid_id: element1.id, position: 1) # added to grid
      page = create(:page)
      create(:page_element, page_id: page.id, element_id: element1.id)
      expect {
        element3.duplicate(page, element1)
      }.to change{element1.reload.elements.count}.by(1) # added to grid
      expect(element1.elements.last.position).to eq(2) # added to end of grid
      expect(element1.elements.last.question_grid).to eq(element1) # added to the right grid
      expect(element1.elements.last.pages).to eq([]) # not added to any pages
    end
    it 'should duplicate question' do
      element1 = create(:question_grid)
      element2 = create(:text_field_element)
      element3 = create(:text_field_element)
      page = create(:page)
      create(:page_element, page_id: page.id, element_id: element1.id)
      create(:page_element, page_id: page.id, element_id: element2.id)
      create(:page_element, page_id: page.id, element_id: element3.id)
      expect {
        element3.duplicate(page)
      }.to change{page.reload.elements.count}.by(1)
      expect(page.page_elements.last.position).to eq(4)
      expect(page.elements.last.question_grid).to be_nil
      expect(page.elements.last.pages).to eq([page])
    end
  end
  
  context '#update_page_all_element_ids' do
    it 'should rebuild all_element_ids in all pages' do
      element1 = create(:text_field_element)
      page1 = create(:page)
      page2 = create(:page)
      create(:page_element, page_id: page1.id, element_id: element1.id)
      create(:page_element, page_id: page2.id, element_id: element1.id)
      page1.update_column(:all_element_ids, nil)
      page2.update_column(:all_element_ids, nil)
      element1.pages.reload
      element1.update_page_all_element_ids
      expect(page1.reload.all_element_ids).to eq("#{element1.id}")
      expect(page2.reload.all_element_ids).to eq("#{element1.id}")
    end
    it 'should rebuild all_element_ids when adding a question grid' do
      page = create(:page)
      grid = create(:question_grid)
      create(:page_element, page_id: page.id, element_id: grid.id)
      grid.pages.reload
      textfield = create(:text_field_element, question_grid: grid)

      page.update_column(:all_element_ids, nil)
      textfield.update_page_all_element_ids
      expect(page.reload.all_element_ids).to eq("#{grid.id},#{textfield.id}")
    end
    it 'should rebuild all_element_ids when adding a question grid with total' do
      page = create(:page)
      grid = create(:question_grid)
      create(:page_element, page_id: page.id, element_id: grid.id)
      grid.pages.reload
      textfield = create(:text_field_element, question_grid: grid)

      page.update_column(:all_element_ids, nil)
      textfield.update_page_all_element_ids
      expect(page.reload.all_element_ids).to eq("#{grid.id},#{textfield.id}")
    end
  end

  context 'translations' do
    it 'uses the translation' do
      e = create(:text_field_element, label_translations: { 'fr' => 'fr label' }, tip_translations: { 'fr' => 'fr tip' }, 
                 content_translations: { 'fr' => 'fr content' })
      expect(e.label('fr')).to eq('fr label')
      expect(e.content('fr')).to eq('fr content')
      expect(e.tooltip('fr')).to eq('fr tip')
    end
    it 'shows english if the translation is an empty string' do
      e = create(:text_field_element, label_translations: { 'fr' => '' }, tip_translations: { 'fr' => '' }, 
                 content_translations: { 'fr' => '' })
      expect(e.label('fr')).to eq(e[:label])
      expect(e.content('fr')).to eq(e[:content])
      expect(e.tooltip('fr')).to eq(e[:tooltip])
    end
    it 'uses english choices if the translation is an empty string' do
      e = create(:choice_field_element, style: 'drop-down', content: "1\r\n2", content_translations: { 'fr' => '' })
      expect(e.choices('fr')).to eq([['1', '1'], ['2', '2']])
    end
  end

  context '#css_classes' do
    it 'splits the css classes into an array' do
      e = create(:text_field_element, css_class: 'a    1 2')
      expect(e.css_classes).to eq(%w(a 1 2))
    end
    it 'handles nil' do
      e = create(:text_field_element, css_class: nil)
      expect(e.css_classes).to eq([])
    end
  end

  context '#matches_filter' do
    let(:e) { create(:text_field_element, is_confidential: true, share: true, hide_label: false) }

    it 'matches when all filter methods match' do
      expect(e.matches_filter([:is_confidential, :share])).to be true
    end
    it "doesn't matches when any methods is false" do
      expect(e.matches_filter([:is_confidential, :hide_label])).to be false
    end
    it "doesn't matches when all methods are false" do
      expect(e.matches_filter([:hide_label])).to be false
    end
  end
end
