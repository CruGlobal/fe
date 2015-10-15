class AddConditionalAnswerToElements < ActiveRecord::Migration
  def change
    add_column Fe::Element.table_name, :conditional_answer, :text
  end
end
