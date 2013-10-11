class AddElementAndAnswerFields < ActiveRecord::Migration
  def change
    add_column Element.table_name, :conditional_id,     :integer
    add_column Element.table_name, :tooltip,            :text
    add_column Element.table_name, :hide_label,         :boolean, :default => false, :nil => false
    add_column Element.table_name, :hide_option_labels, :boolean, :default => false, :nil => false

    add_index Answer.table_name, :answer_sheet_id
    add_index Answer.table_name, :question_id
  end
end
