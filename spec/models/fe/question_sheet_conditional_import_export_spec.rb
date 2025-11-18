require 'rails_helper'

describe Fe::QuestionSheet, 'conditional import/export', type: :model do
  let!(:temp_yaml_file) { Rails.root.join('tmp', 'test_export.yml') }

  after do
    File.delete(temp_yaml_file) if File.exist?(temp_yaml_file)
  end

  context 'conditional element and page mapping during export/import' do
    it 'should preserve conditional relationships after export and import' do
      # Create question sheet with two pages
      question_sheet = create(:question_sheet, label: "Conditional Test Sheet")

      # Page 1 - contains element-to-element conditional
      page1 = create(:page, question_sheet: question_sheet, label: "Personal Info", number: 1)

      # Page 2 - target for page conditional
      page2 = create(:page, question_sheet: question_sheet, label: "Additional Details", number: 2)

      # Page 1: Simple text field
      name_field = create(:text_field_element, label: "Your Name")
      create(:page_element, page: page1, element: name_field)

      # Page 1: Yes/No question that controls visibility of next element on same page
      has_spouse_field = create(:choice_field_element,
        label: "Are you married?",
        style: "yes-no",
        content: "Yes\r\nNo",
        conditional_type: "Fe::Element"
      )
      create(:page_element, page: page1, element: has_spouse_field)

      # Page 1: Element conditionally shown based on previous yes/no
      spouse_name_field = create(:text_field_element, label: "Spouse Name")
      create(:page_element, page: page1, element: spouse_name_field)

      # Page 1: Yes/No question that controls visibility of entire next page
      has_children_field = create(:choice_field_element,
        label: "Do you have children?",
        style: "yes-no",
        content: "Yes\r\nNo",
        conditional_type: "Fe::Page"
      )
      create(:page_element, page: page1, element: has_children_field)

      # Page 2: Simple text field (entire page controlled by has_children_field)
      children_details_field = create(:text_field_element, label: "Tell us about your children")
      create(:page_element, page: page2, element: children_details_field)

      # Set up the conditionals properly
      page1.reload
      page2.reload

      # Update all_element_ids for proper ordering
      page1.update_column(:all_element_ids, "#{name_field.id},#{has_spouse_field.id},#{spouse_name_field.id},#{has_children_field.id}")
      page2.update_column(:all_element_ids, "#{children_details_field.id}")

      # Set up conditional relationships
      has_spouse_field.reload
      has_spouse_field.update!(conditional_id: spouse_name_field.id)

      has_children_field.reload
      has_children_field.update!(conditional_id: page2.id)

      # Verify setup
      expect(has_spouse_field.conditional_type).to eq("Fe::Element")
      expect(has_spouse_field.conditional_id).to eq(spouse_name_field.id)
      expect(has_children_field.conditional_type).to eq("Fe::Page")
      expect(has_children_field.conditional_id).to eq(page2.id)

      # Export to YAML
      File.write(temp_yaml_file, question_sheet.export_to_yaml)
      expect(File.exist?(temp_yaml_file)).to be true

      # Store original IDs for comparison
      original_spouse_element_id = spouse_name_field.id
      original_page2_id = page2.id
      original_has_spouse_conditional_id = has_spouse_field.conditional_id
      original_has_children_conditional_id = has_children_field.conditional_id

      # Import from YAML (creates new sheet with new IDs)
      imported_sheet = Fe::QuestionSheet.create_from_yaml(temp_yaml_file)

      # Verify basic structure
      expect(imported_sheet.pages.count).to eq(2)
      expect(imported_sheet.all_elements.count).to eq(5)

      # Get imported elements by their labels
      imported_page1 = imported_sheet.pages.find_by(label: "Personal Info")
      imported_page2 = imported_sheet.pages.find_by(label: "Additional Details")

      imported_name_field = imported_sheet.all_elements.find_by(label: "Your Name")
      imported_has_spouse_field = imported_sheet.all_elements.find_by(label: "Are you married?")
      imported_spouse_name_field = imported_sheet.all_elements.find_by(label: "Spouse Name")
      imported_has_children_field = imported_sheet.all_elements.find_by(label: "Do you have children?")
      imported_children_details_field = imported_sheet.all_elements.find_by(label: "Tell us about your children")

      # Verify all elements were imported
      expect(imported_name_field).to be_present
      expect(imported_has_spouse_field).to be_present
      expect(imported_spouse_name_field).to be_present
      expect(imported_has_children_field).to be_present
      expect(imported_children_details_field).to be_present

      # Verify IDs are different (new database records)
      expect(imported_spouse_name_field.id).not_to eq(original_spouse_element_id)
      expect(imported_page2.id).not_to eq(original_page2_id)

      # Verify element-to-element conditional was properly mapped
      expect(imported_has_spouse_field.conditional_type).to eq("Fe::Element")
      expect(imported_has_spouse_field.conditional_id).to eq(imported_spouse_name_field.id)
      expect(imported_has_spouse_field.conditional_id).not_to eq(original_has_spouse_conditional_id)

      # Verify element-to-page conditional was properly mapped
      expect(imported_has_children_field.conditional_type).to eq("Fe::Page")
      expect(imported_has_children_field.conditional_id).to eq(imported_page2.id)
      expect(imported_has_children_field.conditional_id).not_to eq(original_has_children_conditional_id)
    end
  end
end
