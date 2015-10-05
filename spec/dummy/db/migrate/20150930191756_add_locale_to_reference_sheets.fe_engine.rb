# This migration comes from fe_engine (originally 20150930191538)
class AddLocaleToReferenceSheets < ActiveRecord::Migration
  def change
    add_column Fe::ReferenceSheet.table_name, :locale, :string, default: 'en'
  end
end
