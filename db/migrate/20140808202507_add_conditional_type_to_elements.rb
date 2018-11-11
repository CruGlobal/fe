class AddConditionalTypeToElements < ActiveRecord::Migration[4.2]
  def change
    add_column Fe::Element.table_name, :conditional_type, :string
  end
end
