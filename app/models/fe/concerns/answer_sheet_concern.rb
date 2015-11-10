module Fe
  module AnswerSheetConcern
    extend ActiveSupport::Concern

    begin
      included do
        has_many :answer_sheet_question_sheets, foreign_key: 'answer_sheet_id', class_name: '::Fe::AnswerSheetQuestionSheet'
        has_many :question_sheets, through: :answer_sheet_question_sheets, class_name: 'Fe::QuestionSheet'
        has_many :answers, ->(answer_sheet) {
          question_sheet_ids = answer_sheet.question_sheet_ids

          if question_sheet_ids.any?
            element_ids = Fe::Page.joins(:question_sheet).where(question_sheet_id: question_sheet_ids).pluck(:all_element_ids).compact
            element_ids = element_ids.collect{ |e| e.split(',') }.flatten
          end

          unless question_sheet_ids.any? && element_ids.any?
            # an answer sheet not assigned to a question sheet, or assigned to
            # a question sheet with no elements should not return any answers
            return where('false')
          end

          where('question_id' => element_ids)

        }, foreign_key: 'answer_sheet_id', class_name: '::Fe::Answer'
        has_many :reference_sheets, :foreign_key => 'applicant_answer_sheet_id', class_name: 'Fe::ReferenceSheet'
        has_many :payments, :foreign_key => 'application_id', class_name: 'Fe::Payment'
      end
    rescue ActiveSupport::Concern::MultipleIncludedBlocks
    end

    def languages
      return [] unless question_sheets.first

      unless @languages
        @languages = question_sheets.first.languages
        question_sheets[1..-1].each { |qs| @languages &= qs.languages.select(&:present?) }
      end
      @languages
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

    def percent_complete(required_only = true)
      countable_questions = question_sheets.collect{ |qs| qs.all_elements.questions }.flatten
      countable_questions.reject!{ |e| e.hidden?(self) }
      countable_questions.reject!{ |e| !e.required } if required_only

      num_questions = countable_questions.length
      return 0 if num_questions == 0
      num_answers = answers
        .where("(question_id IN (?) AND value IS NOT NULL) AND (value != '')", countable_questions.collect(&:id))
        .select("DISTINCT question_id").count
      [ [ (num_answers.to_f / num_questions.to_f * 100.0).to_i, 100 ].min, 0 ].max
    end

    def collat_title() "" end

    def question_sheet_ids
      question_sheets.collect(&:id)
    end
  end
end
