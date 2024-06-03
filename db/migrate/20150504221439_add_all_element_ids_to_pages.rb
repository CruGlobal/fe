class AddAllElementIdsToPages < ActiveRecord::Migration[4.2]
  def change
    add_column Fe::Page.table_name, :all_element_ids, :text
  end
end
