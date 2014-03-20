class AddMaxLengths < ActiveRecord::Migration
  def change
    add_column Fe::Element.table_name, :max_length, :integer
    
    add_index Fe::Element.table_name, :conditional_id
    add_index Fe::Element.table_name, :question_grid_id
  end
end
