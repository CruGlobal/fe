class AddVisibleAndVisibilityCacheKeyToReferenceSheets < ActiveRecord::Migration
  def change
    add_column Fe::ReferenceSheet.table_name, :visible, :boolean
    add_column Fe::ReferenceSheet.table_name, :visibility_cache_key, :string
  end
end
