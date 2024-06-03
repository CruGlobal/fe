# This migration comes from fe_engine (originally 20150925181652)
class AddShareToElements < ActiveRecord::Migration[4.2]
  def change
    add_column Fe::Element.table_name, :share, :boolean, default: false
  end
end
