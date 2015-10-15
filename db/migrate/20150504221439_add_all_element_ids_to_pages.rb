class AddAllElementIdsToPages < ActiveRecord::Migration
  def change
    add_column Fe::Page.table_name, :all_element_ids, :text
  end
end
