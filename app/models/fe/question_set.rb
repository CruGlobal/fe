# QuestionSet
# represents a group of elements, with their answers
module Fe
  class QuestionSet

    attr_reader :elements, :questions

    # associate answers from database with a set of elements
    def initialize(elements, answer_sheet)
      @elements = elements
      @answer_sheet = answer_sheet
      @questions = elements.select { |e| e.question? }
    end

    # update with responses from form
    def post(params, answer_sheet)
      questions_indexed = @questions.index_by(&:id)

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
      AnswerSheet.transaction do
        @questions.each do |question|
          question.save_response(@answer_sheet)
        end
      end
    end

    # options should contain:
    # 
    # :filter - Array of symbols, ex [ :confidential ]
    #
    #           These will be called on each element to determine if they match the filter
    #           An element matches the filter using an AND condition, ie. if all the methods
    #           in the array return true
    # 
    # :filter_default - Either :show or :hide
    #
    #           If show, all elements are shown by default and hidden if they match the filter.
    #           If hide, all elements are hidden by default and shown if they match the filter.
    #
    def set_filter(options = {})
      return if options.nil? || options.empty?

      filter = options.delete(:filter)
      unless filter && filter.is_a?(Array)
        raise("expect options[:filter] to be an array")
      end
      filter_default = options.delete(:filter_default)
      unless filter_default && [:show, :hide].include?(filter_default)
        raise("expect options[:filter_default] to be either :show or :hide")
      end

      @filter = filter
      @filter_default = filter_default

      matching_ids = []
      @elements.each do |e|
        if e.matches_filter(@filter) && !matching_ids.include?(e.id)
          matching_ids << e.id
          matching_ids += e.all_elements.collect(&:id)
        end
      end

      case filter_default
      when :show
        @elements = @elements.to_a.reject{ |e| matching_ids.include?(e.id) }
      when :hide
        @elements = @elements.to_a.select{ |e| matching_ids.include?(e.id) }
      end

      initialize(@elements, @answer_sheet)
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
          values = [Date.new(year.to_i, month.to_i, 1).strftime('%Y-%m-%d')]  # for mm/yy drop downs
        end
      elsif param.kind_of?(Hash)
        # from Hash with multiple answers per question
        # If value is also a hash, use the value hash without escaping or anything,
        # so that custom elements can be implemented by handling set_response.
        values = param.values.map {|v| v.is_a?(Hash) ? v : CGI.unescape(v)}
      elsif param.kind_of?(String)
        values = [CGI.unescape(param)]
      end

      # Hash may contain empty string to force post for no checkboxes
  #    values = values.reject {|r| r == ''}
    end
  end
end
