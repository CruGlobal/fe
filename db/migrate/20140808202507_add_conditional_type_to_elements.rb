class AddConditionalTypeToElements < ActiveRecord::Migration
  def change
    add_column Fe::Element.table_name, :conditional_type, :string
  end
end
