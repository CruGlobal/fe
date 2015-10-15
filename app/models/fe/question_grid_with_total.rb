# QuestionGrid
# - Represents a grid layout of a set of questions, with a total at the bottom
#
# :kind         - 'QuestionGridWithTotal' for single table inheritance (STI)
# :content      - questions
# :total_cols    - Which column(s) of the grid should be used for totals

module Fe
  class QuestionGridWithTotal < QuestionGrid
    def totals(app)
      totals = []
      col = 0
      row = []
      elements.each do |el|
        value = el.display_response(app) if el.respond_to?(:display_response) && el.display_response(app).present?

        if value && value.present? # keep totals nil until there actually is a value, so that we can only display a total only if at least one row had a value
          value = value.tr("^0-9.", '').to_f
          totals[col] = (totals[col].present? ? totals[col] + value : value)
        end
        col = (col + 1) % num_cols
      end
      totals
    end
  end
end
