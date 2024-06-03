# This migration comes from fe_engine (originally 20140808202507)
class AddConditionalTypeToElements < ActiveRecord::Migration[4.2]
  def change
    add_column Fe::Element.table_name, :conditional_type, :string
  end
end
