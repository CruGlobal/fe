# This migration comes from fe_engine (originally 20150714220730)
class AddLocaleToAnswerSheet < ActiveRecord::Migration
  def change
    add_column Fe.answer_sheet_class.constantize.table_name, :locale, :string, default: 'en'
  end
end
