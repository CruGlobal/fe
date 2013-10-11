class AddMaxLengths < ActiveRecord::Migration
  def change
    add_column Element.table_name, :max_length, :integer
    
    add_index Element.table_name, :conditional_id
    add_index Element.table_name, :question_grid_id
  end
end
