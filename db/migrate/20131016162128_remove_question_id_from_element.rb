class RemoveQuestionIdFromElement < ActiveRecord::Migration[4.2]
  def up
    remove_column Fe::Element.table_name, :question_sheet_id
  end
  
  def down
    add_column Fe::Element.table_name, :question_sheet_id, :integer
  end
end
