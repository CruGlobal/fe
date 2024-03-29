# ReferenceQuestion
# - a question that provides a fields to specify a reference
module Fe
  class ReferenceQuestion < Question
    has_many :reference_sheets, foreign_key: :question_id

    after_save :update_references_question_sheet_ids

    def response(app=nil)
      return unless app
      # A reference is the same if the related_question_sheet corresponding to the question is the same
      reference = Fe::ReferenceSheet.find_by_applicant_answer_sheet_id_and_question_id(app.id, id)
      reference || Fe::ReferenceSheet.create(applicant_answer_sheet_id: app.id, question_id: id)
    end

    def has_response?(app = nil)
      if app
        reference = response(app)
        reference && reference.valid?
      else
        Fe::ReferenceSheet.where(question_id: id).count > 0
      end
    end

    def display_response(app = nil, humanize = false)
      response(app).to_s
    end

    # which view to render this element?
    def ptemplate
      "fe/reference_#{style}"
    end

    def update_references_question_sheet_ids
      reference_sheets.where(status: :created).update_all(question_sheet_id: related_question_sheet_id, updated_at: Time.now)
    end
  end
end
