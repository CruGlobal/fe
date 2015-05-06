# This migration comes from fe_engine (originally 20150504221439)
class AddAllElementIdsToPages < ActiveRecord::Migration
  def change
    add_column Fe::Page.table_name, :all_element_ids, :string
  end
end
