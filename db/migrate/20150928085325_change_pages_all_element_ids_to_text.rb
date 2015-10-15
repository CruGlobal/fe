class ChangePagesAllElementIdsToText < ActiveRecord::Migration
  def change
    change_column Fe::Page.table_name, :all_element_ids, :text
  end
end
