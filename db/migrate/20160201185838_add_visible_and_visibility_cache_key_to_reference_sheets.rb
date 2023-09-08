class AddVisibleAndVisibilityCacheKeyToReferenceSheets < ActiveRecord::Migration[4.2]
  def change
    add_column Fe::ReferenceSheet.table_name, :visible, :boolean
    add_column Fe::ReferenceSheet.table_name, :visibility_cache_key, :string
  end
end
