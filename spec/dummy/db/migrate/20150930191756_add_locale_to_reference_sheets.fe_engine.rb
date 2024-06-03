# This migration comes from fe_engine (originally 20150930191538)
class AddLocaleToReferenceSheets < ActiveRecord::Migration[4.2]
  def change
    add_column Fe::ReferenceSheet.table_name, :locale, :string, default: 'en'
  end
end
