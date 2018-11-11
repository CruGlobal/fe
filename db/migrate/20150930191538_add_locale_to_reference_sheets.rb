class AddLocaleToReferenceSheets < ActiveRecord::Migration[4.2]
  def change
    add_column Fe::ReferenceSheet.table_name, :locale, :string, default: 'en'
  end
end
