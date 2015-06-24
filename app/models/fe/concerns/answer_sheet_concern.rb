module Fe
  module AnswerSheetConcern
    extend ActiveSupport::Concern

    begin
      included do
        has_many :answer_sheet_question_sheets, foreign_key: 'answer_sheet_id', class_name: '::Fe::AnswerSheetQuestionSheet'
        has_many :question_sheets, through: :answer_sheet_question_sheets, class_name: 'Fe::QuestionSheet'
        has_many :answers, ->(answer_sheet) { 
          question_sheet_ids = answer_sheet.question_sheet_ids

          if question_sheet_ids.present?
            element_ids = Fe::Element.joins(pages: :question_sheet).where("#{Fe::Page.table_name}.question_sheet_id" => question_sheet_ids).pluck("#{Fe::Element.table_name}.id")
          else
            # an answer sheet not assigned to a question sheet should not return any answers
            return where('false') 
          end

          # get question grid answers as well
          element_ids += Fe::Element.joins(question_grid: { pages: :question_sheet }).where("#{Fe::Page.table_name}.question_sheet_id" => question_sheet_ids).pluck("#{Fe::Element.table_name}.id")

          where('question_id' => element_ids)

        }, foreign_key: 'answer_sheet_id', class_name: '::Fe::Answer'
        has_many :reference_sheets, :foreign_key => 'applicant_answer_sheet_id', class_name: 'Fe::ReferenceSheet'
        has_many :payments, :foreign_key => 'application_id', class_name: 'Fe::Payment'
      end
    rescue ActiveSupport::Concern::MultipleIncludedBlocks
    end

    def complete?
      !completed_at.nil?
    end

    # answers for this sheet, grouped by question id
    def answers_by_question
      @answers_by_question ||= answers.group_by { |answer| answer.question_id }
    end

    # Convenience method if there is only one question sheet in your system
    def question_sheet
      question_sheets.first
    end

    def pages
      Page.where(:question_sheet_id => question_sheets.collect(&:id)).order('number')
    end

    def completely_filled_out?
      pages.all? {|p| p.complete?(self)}
    end

    def has_answer_for?(question_id)
      !answers_by_question[question_id].nil?
    end

    def reference?
      false
    end

    def percent_complete
      num_questions = question_sheets.inject(0.0) { |sum, qs| qs.nil? ? sum : qs.questions_count + sum }
      return 0 if num_questions == 0
      num_answers = answers.where("(value IS NOT NULL) AND (value != '')").select("DISTINCT question_id").count
      [ [ (num_answers.to_f / num_questions.to_f * 100.0).to_i, 100 ].min, 0 ].max
    end

    def collat_title() "" end

    def question_sheet_ids
      question_sheets.collect(&:id)
    end
  end
end
