class AddLocaleColumns < ActiveRecord::Migration[4.2]
  def change
    add_column Fe::QuestionSheet.table_name, :languages, :text
    add_column Fe::Element.table_name, :label_translations, :text
    add_column Fe::Element.table_name, :tip_translations, :text
    add_column Fe::Element.table_name, :content_translations, :text
    add_column Fe::Page.table_name, :label_translations, :text
  end
end
