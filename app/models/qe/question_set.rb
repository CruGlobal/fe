module Qe
  class QuestionSet
    

extend ActiveSupport::Concern  

  included do
    attr_reader :elements
  end

  # associate answers from database with a set of elements
  def initialize(elements, answer_sheet)
    @elements = elements
    @answer_sheet = answer_sheet
  
    @questions = elements.select { |e| e.question? }
  
    # answers = @answer_sheet.answers_by_question
  
    @questions.each do |question|
      question.answers = question.responses(answer_sheet) #answers[question.id]
    end    
    @questions
  end
  
  # update with responses from form
  def post(params, answer_sheet)
    questions_indexed = @questions.index_by {|q| q.id}
    
    # loop over form values
    params ||= {}
    params.each do |question_id, response|
      next if questions_indexed[question_id.to_i].nil? # the rare case where a question was removed after the app was opened.
      # update each question with the posted response
      questions_indexed[question_id.to_i].set_response(posted_values(response), answer_sheet)
    end
  end
  # 
  # def valid?
  #   valid = true
  #   @questions.each do |question|
  #     valid = false unless question.valid_response?  # run through ALL questions
  #   end
  #   valid
  # end
  
  def any_questions?
    @questions.length > 0
  end
  
  def save
    Qe::AnswerSheet.transaction do
      @questions.each do |question|
        question.save_response(@answer_sheet)
      end
    end
  end
  
  private
  
  # convert posted response to a question into Array of values
  def posted_values(param)
  
    if param.kind_of?(Hash) and param.has_key?('year') and param.has_key?('month')
      year = param['year']
      month = param['month']
      if month.blank? or year.blank?
        values = ''
      else
        values = [Date.new(year.to_i, month.to_i, 1).strftime('%m/%d/%Y')]  # for mm/yy drop downs
      end
    elsif param.kind_of?(Hash)
      # from Hash with multiple answers per question
      values = param.values.map {|v| CGI.unescape(v)}
    elsif param.kind_of?(String)
      values = [CGI.unescape(param)]
    end
  
    # Hash may contain empty string to force post for no checkboxes
    # values = values.reject {|r| r == ''}
  end
    
  end
end
