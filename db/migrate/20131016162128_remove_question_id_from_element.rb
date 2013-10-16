class RemoveQuestionIdFromElement < ActiveRecord::Migration
  def up
    remove_column Element.table_name, :question_sheet_id
  end
  
  def down
    add_column Element.table_name, :question_sheet_id, :integer
  end
end
