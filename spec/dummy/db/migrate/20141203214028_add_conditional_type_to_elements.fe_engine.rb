# This migration comes from fe_engine (originally 20140808202507)
class AddConditionalTypeToElements < ActiveRecord::Migration
  def change
    add_column Fe::Element.table_name, :conditional_type, :string
  end
end
