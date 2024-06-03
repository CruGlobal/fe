class Fe::UpdateReferenceSheetVisibilityJob < ActiveJob::Base
  def perform(answer_sheet, question_ids)
    answer_sheet.question_sheets_all_reference_elements.each do |r|
      if (r.visibility_affecting_element_ids & question_ids).any?
        answer_sheet.all_references.where(question_id: r.id).each do |ref|
          ref.update_visible
        end
      end
    end
  end
end
