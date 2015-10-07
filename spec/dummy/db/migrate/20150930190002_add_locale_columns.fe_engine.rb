# This migration comes from fe_engine (originally 20150713022326)
class AddLocaleColumns < ActiveRecord::Migration
  def change
    add_column Fe::QuestionSheet.table_name, :languages, :text
    add_column Fe::Element.table_name, :label_translations, :text
    add_column Fe::Element.table_name, :tip_translations, :text
    add_column Fe::Element.table_name, :content_translations, :text
    add_column Fe::Page.table_name, :label_translations, :text
  end
end
