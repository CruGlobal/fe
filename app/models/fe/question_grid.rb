# QuestionGrid
# - Represents a grid layout of a set of questions
#
# :kind         - 'QuestionGrid' for single table inheritance (STI)
# :content      - questions

module Fe
  class QuestionGrid < Element

    has_many :elements, -> { order('position asc, id asc') },
             :class_name => "Element",
             :foreign_key => "question_grid_id",
             :dependent => :nullify

    def num_cols
      num = cols.to_s.split(';').length
      num = 1 if num == 0
      num
    end

    def has_response?(answer_sheet = nil)
      elements.any? {|e| e.has_response?(answer_sheet)}
    end

    def export_hash
      super_hash = super
      children = elements.collect do |e|
        h = e.export_hash
        h[:question_grid_id] = :parent_id
        h
      end

      super_hash[:children] += children
      super_hash
    end
  end
end
